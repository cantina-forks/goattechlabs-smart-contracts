// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LLocker {
    struct SLock {
        uint startedAt;
        uint amount;
        uint duration;
    }

    function getLockId(
        address account_,
        address poolOwner_
    )
        internal
        pure
        returns(bytes32)
    {
        return keccak256(abi.encodePacked(account_, poolOwner_));
    }

    function restDuration(
        SLock memory lockData_
    )
        internal
        view
        returns(uint)
    {
        if (lockData_.startedAt > block.timestamp) {
            return lockData_.duration + lockData_.startedAt - block.timestamp;
        }
        uint pastTime = block.timestamp - lockData_.startedAt;
        if (pastTime < lockData_.duration) {
            return lockData_.duration - pastTime;
        } else {
            return 0;
        }
    }

    function prolong(
        SLock storage lockData_,
        uint amount_,
        uint duration_
    )
        internal
    {
        if (lockData_.amount == 0) {
            require(amount_ > 0 && duration_ > 0, "amount_ = 0 or duration_ = 0");
        } else {
            require(amount_ > 0 || duration_ > 0, "amount_ = 0 and duration_ = 0");
        }

        lockData_.amount += amount_;

        uint rd = restDuration(lockData_);
        if (rd == 0) {
            lockData_.duration = duration_;
            lockData_.startedAt = block.timestamp;
            return;
        }

        lockData_.duration += duration_;
    }

    function isUnlocked(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        view
        returns(bool)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        uint elapsedTime = block.timestamp - lockData_.startedAt;
        return elapsedTime >= duration;
    }

    function calDuration(
        SLock memory lockData_,
        uint fs_,
        bool isPoolOwner_
    )
        internal
        pure
        returns(uint)
    {
        uint mFactor = isPoolOwner_ ? 2 * LPercentage.DEMI - fs_ : fs_;
        uint duration = lockData_.duration * mFactor / LPercentage.DEMI;
        return duration;
    }
}
