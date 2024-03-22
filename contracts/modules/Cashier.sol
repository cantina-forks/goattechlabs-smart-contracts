// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Cashier {
    event SetCleanTo(
        address indexed cleanTo
    );

    event Clean(
        uint amount
    );

    uint private _lastestBalance;

    IERC20 private _token;

    address private _cleanTo;

    bool private _isCleanEnabled;

    function _initCashier(
        address token_,
        address cleanTo_
    )
        internal
    {
        _token = IERC20(token_);
        _setCleanTo(cleanTo_);
    }

    function _setCleanTo(
        address cleanTo_
    )
        internal
    {
        _cleanTo = cleanTo_;
        _isCleanEnabled = cleanTo_ != address(this);
        emit SetCleanTo(cleanTo_);
    }

    function _updateBalance()
        internal
    {
        _lastestBalance = _token.balanceOf(address(this));
    }

    function _cashIn()
        internal
        returns(uint)
    {
        uint incBalance = currentBalance() - _lastestBalance;
        _updateBalance();
        return incBalance;
    }

    function _cashOut(
        address to_,
        uint amount_
    )
        internal
    {
        _token.transfer(to_, amount_);
        _updateBalance();
    }

    // todo
    // check all clean calls logic
    // lockers
    // earnings
    // voting
    // distributors
    // vester
    /*
        cleanTo

        eLocker : eP2pDistributor
        dLocker : 0xDEAD

        eEarning : eP2pDistributor
        dEarning : 0xDEAD

        eVoting : eP2pDistributor
        dVoting : 0xDEAD

        distributors: revert all

        eVester : eP2pDistributor
        dVester : 0xDEAD

    */

    function clean()
        public
        virtual
    {
        require(_isCleanEnabled, "unable to clean");
        uint currentBal = currentBalance();
        if (currentBal > _lastestBalance) {
            uint amount = currentBal - _lastestBalance;
            _token.transfer(_cleanTo, amount);
            emit Clean(amount);
        }
        _updateBalance();
    }

    function cleanTo()
        external
        view
        returns(address)
    {
        return _cleanTo;
    }

    function currentBalance()
        public
        view
        returns(uint)
    {
        return _token.balanceOf(address(this));
    }

    function lastestBalance()
        public
        view
        returns(uint)
    {
        return _lastestBalance;
    }
}
