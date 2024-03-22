// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PERC20.sol";
import "./Cashier.sol";

import "../interfaces/IProfile.sol";

contract Earning is Cashier, PERC20 {

    event UpdateMaxEarning(
        address indexed account,
        uint maxEarning
    );

    event ShareCommission(
        address indexed account,
        address indexed profile,
        uint sAmount
    );

    event Withdraw(
        address indexed account,
        uint amount,
        address dest
    );

    mapping(address => uint) private _sharedA;
    mapping(address => uint) private _maxEarningOf;
    IProfile private _profileC;

    function initEarning(
        address token_,
        address profileCAddr_,
        address accessControl_,
        string memory name_,
        string memory symbol_,
        address cleanTo_
    )
        public
        virtual
        initializer
    {
        _initCashier(token_, cleanTo_);
        _profileC = IProfile(profileCAddr_);
        bool inPrivateMode = true;
        initPERC20(accessControl_, inPrivateMode, name_, symbol_);
    }

    function _updateMaxEarning(
        address account_,
        uint maxEarning_
    )
        internal
    {
        _maxEarningOf[account_] = maxEarning_;
        emit UpdateMaxEarning(account_, maxEarning_);
    }

    function updateMaxEarning(
        address account_,
        uint maxEarning_
    )
        external
        onlyAdmin
    {
        _updateMaxEarning(account_, maxEarning_);
    }

    function shareCommission(
        address account_
    )
        public
    {
        uint amount = balanceOf(account_) - _sharedA[account_];
        if (amount == 0) {
            return;
        }

        address sponsor;
        uint sAmount;
        (sponsor, sAmount) =  _profileC.getSponsorPart(account_, amount);
        if (sAmount > 0) {
            _transfer(account_, sponsor, sAmount);
            emit ShareCommission(account_, sponsor, sAmount);
        }
        _sharedA[account_] = balanceOf(account_);
        if (_sharedA[account_] > _maxEarningOf[account_]) {
            _updateMaxEarning(account_, _sharedA[account_]);
        }
    }

    function update(
        address account_,
        bool needShareComm_
    )
        external
    {
        if (needShareComm_) {
            uint amount = _cashIn();
            _mint(account_, amount);
            shareCommission(account_);
        } else {
            shareCommission(account_);
            uint amount = _cashIn();
            _mint(account_, amount);
            _sharedA[account_] = balanceOf(account_);
            if (_sharedA[account_] > _maxEarningOf[account_]) {
                _updateMaxEarning(account_, _sharedA[account_]);
            }
        }
    }

    function withdraw(
        address account_,
        uint amount_,
        address dest_
    )
        external
        onlyAdmin
    {
        shareCommission(account_);

        _burn(account_, amount_);
        _sharedA[account_] = balanceOf(account_);

        _cashOut(dest_, amount_);
        emit Withdraw(account_, amount_, dest_);
    }

    function maxEarningOf(
        address account_
    )
        external
        view
        returns(uint)
    {
        return _maxEarningOf[account_];
    }

    function earningOf(
        address account_
    )
        external
        view
        returns(uint)
    {
        uint amount = balanceOf(account_) - _sharedA[account_];
        if (amount == 0) {
            return _sharedA[account_];
        }

        address sponsor;
        uint sAmount;
        (sponsor, sAmount) =  _profileC.getSponsorPart(account_, amount);
        return balanceOf(account_) - sAmount;
    }
}
