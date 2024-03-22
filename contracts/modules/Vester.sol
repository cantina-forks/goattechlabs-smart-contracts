// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./Cashier.sol";

import "../lib/LLocker.sol";
import "../interfaces/IProfile.sol";

import "./UseAccessControl.sol";

contract Vester is Cashier, UseAccessControl {
    using LLocker for *;

    event UpdateLockData(
        address indexed account,
        LLocker.SLock lockData
    );

    mapping(address => LLocker.SLock) private _lockData;

    function initVester(
        address accessControl_,
        address token_,
        address cleanTo_
    )
        public
        initializer
    {
        _initCashier(token_, cleanTo_);
        initUseAccessControl(accessControl_);
    }

    function lock(
        address account_,
        uint duration_,
        uint cliff_
    )
        external
        onlyAdmin
    {
        uint amount = _cashIn();
        unlock(account_);
        LLocker.SLock storage lockData = _lockData[account_];
        lockData.amount += amount;
        lockData.duration = duration_;
        lockData.startedAt = block.timestamp + cliff_;
        emit UpdateLockData(account_, _lockData[account_]);
    }

    function transferLock(
        address from_,
        address to_,
        uint amount_
    )
        external
        onlyAdmin
    {
        unlock(from_);
        unlock(to_);
        LLocker.SLock storage lockData;
        lockData = _lockData[from_];
        lockData.amount -= amount_;
        uint duration = lockData.duration;
        emit UpdateLockData(from_, lockData);
        lockData = _lockData[to_];
        lockData.amount += amount_;
        if (lockData.duration < duration) {
            lockData.duration = duration;
        }
        emit UpdateLockData(to_, lockData);
    }

    function unlock(
        address account_
    )
        public
    {
        LLocker.SLock storage lockData = _lockData[account_];
        if (lockData.amount == 0 || lockData.startedAt > block.timestamp) return;
        uint airdrop = _cashIn();
        (uint restA, uint restDuration) = currentLockData(account_);
        uint toUnlockA = lockData.amount - restA;
        lockData.startedAt = block.timestamp;
        lockData.amount = restA;
        lockData.duration = restDuration;
        uint toTransferA = toUnlockA + airdrop;
        if (toTransferA > 0) {
            _cashOut(account_, toUnlockA + airdrop);
        }
        emit UpdateLockData(account_, _lockData[account_]);
    }

    // function forcedUnlock(
    //     address account_,
    //     uint amount_
    // )
    //     public
    //     onlyAdmin
    // {
    //     unlock(account_);
    //     LLocker.SLock storage lockData = _lockData[account_];
    //     lockData.amount -= amount_;
    //     _cashOut(account_, amount_);
    //     emit UpdateLockData(account_, _lockData[account_]);
    // }

    function currentLockData(
        address account_
    )
        public
        view
        returns(uint restA, uint restDuration)
    {
        LLocker.SLock memory lockData = _lockData[account_];
        restDuration = LLocker.restDuration(lockData);
        restA = restDuration >= lockData.duration
            ? lockData.amount
            : lockData.amount * restDuration / lockData.duration;
    }

    function getUnlockedA(
        address account_
    )
        external
        view
        returns(uint)
    {
        LLocker.SLock memory lockData = _lockData[account_];
        (uint restA,) = currentLockData(account_);
        return lockData.amount - restA;
    }

    function getLockData(
        address account_
    )
        external
        view
        returns(LLocker.SLock memory)
    {
        return _lockData[account_];
    }
}
