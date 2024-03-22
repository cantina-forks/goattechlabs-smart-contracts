// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControl is Ownable {

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "onlyAdmin");
        _;
    }

    event AddAdmin(
        address account
    );

    event RemoveAdmin(
        address account
    );

    mapping(address => bool) private _isAdmin;

    bool private _isPaused;

    function _addAdmin(
        address account_
    )
        internal
    {
        if(!_isAdmin[account_]) {
            _isAdmin[account_] = true;
            emit AddAdmin(account_);
        }
    }

    function _removeAdmin(
        address account_
    )
        internal
    {
        if(_isAdmin[account_]) {
            _isAdmin[account_] = false;
            emit RemoveAdmin(account_);
        }
    }

    /*
        onlyOwner
    */

    function addAdmins(
        address[] memory accounts_
    )
        external
        onlyOwner
    {
        uint i = 0;
        while(i < accounts_.length) {
            _addAdmin(accounts_[i]);
            i++;
        }
    }

    function removeAdmins(
        address[] memory accounts_
    )
        external
        onlyOwner
    {
        uint i = 0;
        while(i < accounts_.length) {
            _removeAdmin(accounts_[i]);
            i++;
        }
    }

    function pause()
        external
        onlyOwner
    {
        _isPaused = true;
    }

    function unpause()
        external
        onlyOwner
    {
        _isPaused = false;
    }

    /*
        view
    */

    function isOwner(
        address account_
    )
        external
        view
        returns(bool)
    {
        return account_ == owner();
    }
    function isAdmin(
        address account_
    )
        external
        view
        returns(bool)
    {
        return _isAdmin[account_] && !_isPaused;
    }

    function isPaused()
        external
        view
        returns(bool)
    {
        return _isPaused;
    }
}
