// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Cashier.sol";

import "./Initializable.sol";

import "./interfaces/IDToken.sol";

import "./UseAccessControl.sol";

contract Distributor is Cashier, Initializable, UseAccessControl {
    modifier onlyDToken() {
        require(msg.sender == address(_dToken), "onlyDToken");
        _;
    }

    event SetReward(
        address indexed account,
        uint prevReward,
        uint reward
    );

    IDToken private _dToken;

    // per token reward
    uint private _ptr;
    uint constant private MFACTOR = 10 ** 18;

    mapping(address => int256) private _adjustedRewardOf;

    function initDistributor(
        address accessControl_,
        address dToken_,
        address rewardToken_
    )
        public
        initializer
    {
        initUseAccessControl(accessControl_);
        _dToken = IDToken(dToken_);
        _initCashier(rewardToken_, address(this));
    }

    function clean()
        public
        pure
        override
    {
        // distributors ignore clean
        revert();
    }

    function _distribute()
        internal
    {
        uint totalSupply = _dToken.totalSupply();
        if (totalSupply != 0) {
            uint amount = _cashIn();
            _ptr += amount * MFACTOR / totalSupply;
        }
    }

    function beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    )
        external
        onlyDToken
    {
        _distribute();
        if (from_ == to_) {
            return;
        }
        address account;
        uint reward;

        account = from_;
        if (account != address(0x0)) {
            reward = rewardOf(account);
            uint nextBalance = _dToken.balanceOf(account) - amount_;
            _setAdjReward(account, reward, reward, nextBalance);
        }

        account = to_;
        if (account != address(0x0)) {
            reward = rewardOf(account);
            uint nextBalance = _dToken.balanceOf(account) + amount_;
            _setAdjReward(account, reward, reward, nextBalance);
        }
    }

    function _setAdjReward(
        address account_,
        uint prevReward,
        uint reward_,
        uint dTokenBalance_
    )
        internal
    {
        _adjustedRewardOf[account_] = int256(dTokenBalance_ * _ptr) - int256(reward_ * MFACTOR);
        emit SetReward(account_, prevReward, reward_);
    }

    function distribute()
        external
    {
        _distribute();
    }

    function calReward(
        uint ptr_,
        uint dTokenBalance_,
        int256 adjustedReward_
    )
        public
        pure
        returns(uint)
    {
        int256 mulReward = int256(dTokenBalance_ * ptr_) - adjustedReward_;
        require(mulReward >= 0, "rewardOf,something gone wrong!");
        return uint(mulReward) / MFACTOR;
    }

    function rewardOf(
        address account_
    )
        public
        view
        returns(uint)
    {
        return calReward(_ptr, _dToken.balanceOf(account_), _adjustedRewardOf[account_]);
    }

    function claimFor(
        address account_,
        address dest_
    )
        external
        onlyAdmin
    {
        uint amount = rewardOf(account_);
        if (amount > 0) {
            // reset reward
            _setAdjReward(account_, amount, 0, _dToken.balanceOf(account_));
            _cashOut(dest_, amount);
        }
    }
}
