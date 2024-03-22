// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Cashier.sol";

import "../lib/LLocker.sol";
import "../interfaces/IProfile.sol";

import "./UseAccessControl.sol";

contract Locker is Cashier, UseAccessControl {
    using LLocker for *;

    event UpdateLockData(
        address indexed account,
        address indexed poolOwner,
        LLocker.SLock lockData
    );

    event Withdraw(
        address indexed account,
        address indexed poolOwner,
        address dest,
        uint amount
    );

    event SelfWithdrawn(
        address indexed account
    );

    event UpdatePenaltyAddress(
        address penaltyAddress
    );

    mapping(bytes32 => LLocker.SLock) private _lockData;
    IProfile private _profileC;

    address private _penaltyAddress;

    function initLocker(
        address accessControl_,
        address token_,
        address profileCAddr_,
        address penaltyAddress_,
        address cleanTo_
    )
        public
        initializer
    {
        _initCashier(token_, cleanTo_);
        initUseAccessControl(accessControl_);
        _profileC = IProfile(profileCAddr_);

        _updatePenaltyAddress(penaltyAddress_);
    }

    function lock(
        address account_,
        address poolOwner_,
        uint duration_
    )
        external
        onlyAdmin
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        uint amount = _cashIn();
        LLocker.prolong(_lockData[lockId], amount, duration_);
        emit UpdateLockData(account_, poolOwner_, _lockData[lockId]);
    }

    // default by admin (controller)
    function withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        external
        onlyApprovedAdmin(account_)
    {
        _withdraw(account_, poolOwner_, dest_, amount_, isForced_);
    }

    function _withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        internal
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        LLocker.SLock storage lockData = _lockData[lockId];
        bool isPoolOwner = account_ == poolOwner_;
        uint fs = _profileC.fsOf(poolOwner_);
        if (!isForced_) {
            require(LLocker.isUnlocked(lockData, fs, isPoolOwner), "not unlocked");
        }
        uint duration = LLocker.calDuration(lockData, fs, isPoolOwner);
        uint pastTime = block.timestamp - lockData.startedAt;
        if (pastTime > duration) {
            pastTime = duration;
        }

        lockData.amount -= amount_;
        uint total = amount_;
        uint receivedA = total * pastTime / duration;
        _cashOut(dest_, receivedA);
        if (total != receivedA) {
            _cashOut(_penaltyAddress, total - receivedA);
        }

        emit Withdraw(account_, poolOwner_, dest_, amount_);
        emit UpdateLockData(account_, poolOwner_, _lockData[lockId]);
    }

    function _updatePenaltyAddress(
        address penaltyAddress_
    )
        internal
    {
        _penaltyAddress = penaltyAddress_;
        emit UpdatePenaltyAddress(penaltyAddress_);
    }

    function updatePenaltyAddress(
        address penaltyAddress_
    )
        external
        onlyOwner
    {
        _updatePenaltyAddress(penaltyAddress_);
    }

    function penaltyAddress()
        external
        view
        returns(address)
    {
        return _penaltyAddress;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        external
        pure
        returns(bytes32)
    {
        return LLocker.getLockId(account_, poolOwner_);
    }

    function getLockDataById(
        bytes32 lockId_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        return _lockData[lockId_];
    }

    function getLockData(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        bytes32 lockId = LLocker.getLockId(account_, poolOwner_);
        return _lockData[lockId];
    }
}
