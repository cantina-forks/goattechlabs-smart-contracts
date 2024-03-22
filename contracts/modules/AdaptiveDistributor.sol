// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./Cashier.sol";

import "./Initializable.sol";

contract AdaptiveDistributor is Cashier, Initializable {
    IERC20 private _dToken;

    event Distribute(
        uint amount,
        uint regSupply
    );

    event Claim(
        address indexed holder,
        uint reward
    );

    event UpdateRegBal(
        address indexed holder,
        uint regBal
    );

    struct SHolder {
        uint regBal;
        uint lastRpt;
        uint lastClaimedAt;
    }

    mapping(address => SHolder) public holders;

    uint public rpt;
    uint public regSupply;

    uint constant private MFACTOR = 1e18;

    function init(
        address dToken_,
        address rewardToken_
    )
        public
        initializer
    {
        _dToken = IERC20(dToken_);
        _initCashier(rewardToken_, address(this));
    }

    function distribute()
        public
    {
        if (regSupply == 0) return;
        uint addedAmount = _cashIn();
        if (addedAmount > 0) {
            rpt += _cashIn() * MFACTOR / regSupply;

            emit Distribute(addedAmount, regSupply);
        }
    }

    function claim()
        public
    {
        claimFor(msg.sender);
    }

    function claimFor(
        address holder_
    )
        public
    {
        distribute();

        uint bal = _dToken.balanceOf(holder_);
        SHolder storage holder = holders[holder_];
        uint deltaRpt = rpt - holder.lastRpt;
        uint reward;
        if (holder.regBal > bal) {
            reward = deltaRpt * bal / MFACTOR;
            uint unregBal = holder.regBal - bal;
            uint removedReward = deltaRpt * unregBal / MFACTOR;
            regSupply -= unregBal;
            if (regSupply == 0) {
                rpt = 0;
                // some weis burnt
            } else {
                rpt += removedReward * MFACTOR / regSupply;
            }
        } else {
            reward = deltaRpt * holder.regBal / MFACTOR;
            regSupply += bal - holder.regBal;
        }

        if (reward > 0) {
            _cashOut(holder_, reward);
            emit Claim(holder_, reward);
        }

        if (holder.regBal != bal) {
            emit UpdateRegBal(holder_, bal);
        }

        holder.regBal = bal;
        holder.lastClaimedAt = block.timestamp;
        holder.lastRpt = rpt;
    }

    function claimableOf(
        address holder_
    )
        public
        view
        returns(uint reward)
    {
        uint bal = _dToken.balanceOf(holder_);
        SHolder memory holder = holders[holder_];
        uint deltaRpt = rpt - holder.lastRpt;
        if (holder.regBal > bal) {
            reward = deltaRpt * bal / MFACTOR;
        } else {
            reward = deltaRpt * holder.regBal / MFACTOR;
        }
    }
}