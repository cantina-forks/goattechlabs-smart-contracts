// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../modules/interfaces/ICashier.sol";

interface IVoting is ICashier {
    struct SVoteBasicInfo{
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

        uint totalClaimed;

        bool isFinalized;
        bool isAttackerWon;
        uint winVal;
        uint winnerPower;
        bool isClosed;
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
        external;

    function getVote(
        uint voteId_
    )
        external
        view
        returns(SVoteBasicInfo memory);

    function claimFor(
        uint voteId_,
        address voter_
    )
        external;


    function defenderEarningFreezedOf(
        address account_
    )
        external
        view
        returns(uint);
}
