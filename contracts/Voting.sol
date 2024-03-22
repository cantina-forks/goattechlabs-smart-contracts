// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./modules/UseAccessControl.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./lib/LPercentage.sol";
import "./lib/LLido.sol";

import "./modules/Cashier.sol";

import "./modules/interfaces/IEarning.sol";
import "./interfaces/IVoting.sol";

contract Voting is UseAccessControl, Cashier {

    modifier onlyInVotingTime(
        uint voteId_
    )
    {
        require(voteId_ < _totalVotes, "invalid voteId");
        SVote storage vote = _votes[voteId_];
        require(vote.startedAt <= block.timestamp, "voting not started");
        require(vote.endAt >= block.timestamp, "voting already ended");
        _;
    }

    struct SVote{
        address attacker;
        address defender;

        uint aEthValue;
        uint dEthValue;

        uint voterPercent;
        uint aQuorum;

        uint startedAt;
        uint endAt;

        uint attackerPower;
        uint defenderPower;
        mapping(address => uint) powerOf;
        mapping(address => bool) isForAttacker;

        uint totalClaimed;
        mapping(address => bool) isClaimed;

        bool isFinalized;
        bool isAttackerWon;
        uint winVal;
        uint winnerPower;
        bool isClosed;
    }

    event CreateVote(
        uint indexed voteId,

        address indexed attacker,
        address indexed defender,

        uint aEthValue,
        uint dEthValue,

        uint voterPercent,
        uint aQuorum,

        uint startedAt,
        uint endAt
    );

    event RemoveVoter(
        uint indexed voteId,
        address indexed voter,
        bool indexed isForAttacker,
        uint power
    );

    event AddVoter(
        uint indexed voteId,
        address indexed voter,
        bool indexed isForAttacker,
        uint power
    );

    event CloseVote(
        uint indexed voteId,
        uint cleanedVal,
        address dest
    );

    event Finalize(
        uint indexed voteId,
        bool isAttackerWon,
        uint winnerPower,
        uint winVal
    );

    event ClaimFor(
        uint indexed voteId,
        address indexed voter,
        uint winVal
    );

    mapping(uint => SVote) private _votes;
    uint private _totalVotes;

    IERC20 private _votingToken;
    IERC20  private _geth;

    IEarning private _eEarning;

    mapping(address => uint) private _defenderEarningFreezedOf;

    receive() external payable {}

    function initVoting(
        address accessControl_,
        address votingTokenAddr_,
        address gethAddr_,
        address eEarningAddr_,
        address cleanTo_
    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);
        _votingToken = IERC20(votingTokenAddr_);
        _geth = IERC20(gethAddr_);
        _initCashier(gethAddr_, cleanTo_);
        _eEarning = IEarning(eEarningAddr_);
    }

    function createVote(
        address attacker_,
        address defender_,

        uint aEthValue_,
        uint dEthValue_,

        uint voterPercent_,
        uint aQuorum_,

        uint startedAt_,
        uint endAt_
    )
        external
        onlyAdmin
    {
        uint voteId = _totalVotes;
        _totalVotes++;
        SVote storage vote = _votes[voteId];
        vote.attacker = attacker_;
        vote.defender = defender_;

        vote.aEthValue = aEthValue_;
        vote.dEthValue = dEthValue_;

        _defenderEarningFreezedOf[defender_] += dEthValue_;

        LPercentage.validatePercent(voterPercent_);
        LPercentage.validatePercent(aQuorum_);
        vote.voterPercent = voterPercent_;
        vote.aQuorum = aQuorum_;
        uint inVal = _cashIn();
        require(aEthValue_ + dEthValue_ == inVal, "eth value incorrect");

        vote.startedAt = startedAt_;
        require(startedAt_ >= block.timestamp, "must start in future");
        vote.endAt = endAt_;
        require(endAt_ >= startedAt_, "duration not negative");
        require(endAt_ < block.timestamp + 365 days, "duration too long");
        emit CreateVote(
            voteId,
            attacker_,
            defender_,
            aEthValue_,
            dEthValue_,
            voterPercent_,
            aQuorum_,
            startedAt_,
            endAt_
        );

        _addVoter(voteId, attacker_, true);
        _addVoter(voteId, defender_, false);
    }

    function _removeVoter(
        uint voteId_,
        address voter_
    )
        internal
    {
        SVote storage vote = _votes[voteId_];
        uint power = vote.powerOf[voter_];
        if (power > 0) {
            if (vote.isForAttacker[voter_]) {
                vote.attackerPower -= power;
            } else {
                vote.defenderPower -= power;
            }
            vote.powerOf[voter_] = 0;
            emit RemoveVoter(voteId_, voter_, vote.isForAttacker[voter_], power);
        }
    }

    function _addVoter(
        uint voteId_,
        address voter_,
        bool isForAttacker_
    )
        internal
    {
        _removeVoter(voteId_, voter_);

        SVote storage vote = _votes[voteId_];
        uint power = _votingToken.balanceOf(voter_);

        uint voteDuration = vote.endAt - vote.startedAt;
        uint pastTime = block.timestamp - vote.startedAt;
        uint restDuration = voteDuration - pastTime;
        power = power * restDuration / voteDuration;

        if (power == 0) {
            // add 1 wei to avoid case totalPower = 0
            power = 1;
        }

        if (isForAttacker_) {
            vote.attackerPower += power;
        } else {
            vote.defenderPower += power;
        }
        vote.powerOf[voter_] = power;
        vote.isForAttacker[voter_] = isForAttacker_;
        emit AddVoter(voteId_, voter_, isForAttacker_, power);
    }

    function updatePower(
        uint voteId_,
        bool isForAttacker_
    )
        external
        onlyInVotingTime(voteId_)
    {
        address voter = msg.sender;
        _addVoter(voteId_, voter, isForAttacker_);
    }

    function _tryFinalize(
        uint voteId_
    )
        internal
    {
        SVote storage vote = _votes[voteId_];
        require(!vote.isFinalized, "already finalized");
        require(vote.endAt < block.timestamp, "vote not ended");

        vote.isFinalized = true;
        uint totalPower = vote.attackerPower + vote.defenderPower;
        uint reqPower = LPercentage.getPercentA(totalPower, vote.aQuorum);
        vote.isAttackerWon = vote.attackerPower > reqPower;

        if (vote.isAttackerWon) {
            vote.winVal = LPercentage.getPercentA(vote.dEthValue, vote.voterPercent);
            vote.winnerPower = vote.attackerPower;
            uint toWinnerVal = vote.aEthValue + vote.dEthValue - vote.winVal;
            address payable to = payable(vote.attacker);
            // refund to attacker
            LLido.sellWsteth(toWinnerVal);
            LLido.wethToEth();
            to.send(address(this).balance);
            clean();
        } else {
            vote.winVal = LPercentage.getPercentA(vote.aEthValue, vote.voterPercent);
            vote.winnerPower = vote.defenderPower;
            uint unfreezeVal = vote.dEthValue;
            uint rewardWinnerVal = vote.aEthValue - vote.winVal;
            address payable to = payable(vote.defender);

            _eEarning.clean();
            // refund to defender
            _cashOut(address(_eEarning), unfreezeVal);
            _eEarning.update(to, false);
            //reward to defender
            _cashOut(address(_eEarning), rewardWinnerVal);
            _eEarning.update(to, true);
        }
        _defenderEarningFreezedOf[vote.defender] -= vote.dEthValue;

        emit Finalize(voteId_, vote.isAttackerWon, vote.winnerPower, vote.winVal);
    }

    function claimFor(
        uint voteId_,
        address voter_
    )
        external
        onlyAdmin
    {
        SVote storage vote = _votes[voteId_];
        require(!vote.isClosed, "already closed");
        if (!vote.isFinalized) {
            _tryFinalize(voteId_);
        }

        require(!vote.isClaimed[voter_], "already claimed");

        vote.isClaimed[voter_] = true;

        require(vote.isAttackerWon == vote.isForAttacker[voter_], "your side lost");

        uint winVal = vote.winVal * vote.powerOf[voter_] / vote.winnerPower;
        require(winVal > 0, "nothing to claim");
        vote.totalClaimed += winVal;

        _eEarning.clean();
        _cashOut(address(_eEarning), winVal);
        _eEarning.update(voter_, true);

        emit ClaimFor(voteId_, voter_, winVal);
    }

    function closeVote(
        uint voteId_,
        address dest_
    )
        external
        onlyAdmin
    {
        SVote storage vote = _votes[voteId_];
        require(vote.isFinalized, "need finalize before");
        require(!vote.isClosed, "already closed");
        vote.isClosed = true;

        uint cleanedVal = vote.winVal - vote.totalClaimed;
        _cashOut(dest_, cleanedVal);
        emit CloseVote(voteId_, cleanedVal, dest_);
    }

    function getVote(
        uint voteId_
    )
        external
        view
        returns(IVoting.SVoteBasicInfo memory)
    {
        IVoting.SVoteBasicInfo memory basicInfo;

        basicInfo.attacker = _votes[voteId_].attacker;
        basicInfo.defender = _votes[voteId_].defender;
        basicInfo.aEthValue = _votes[voteId_].aEthValue;
        basicInfo.dEthValue = _votes[voteId_].dEthValue;
        basicInfo.voterPercent = _votes[voteId_].voterPercent;
        basicInfo.aQuorum = _votes[voteId_].aQuorum;
        basicInfo.startedAt = _votes[voteId_].startedAt;
        basicInfo.endAt = _votes[voteId_].endAt;
        basicInfo.attackerPower = _votes[voteId_].attackerPower;
        basicInfo.defenderPower = _votes[voteId_].defenderPower;
        basicInfo.totalClaimed = _votes[voteId_].totalClaimed;
        basicInfo.isFinalized = _votes[voteId_].isFinalized;
        basicInfo.isAttackerWon = _votes[voteId_].isAttackerWon;
        basicInfo.winVal = _votes[voteId_].winVal;
        basicInfo.winnerPower = _votes[voteId_].winnerPower;
        basicInfo.isClosed = _votes[voteId_].isClosed;

        return basicInfo;
    }

    function defenderEarningFreezedOf(
        address account_
    )
        external
        view
        returns(uint)
    {
        return _defenderEarningFreezedOf[account_];
    }
}
