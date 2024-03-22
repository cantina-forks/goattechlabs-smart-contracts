// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";
import "./LProfile.sol";
import "../lib/LLocker.sol";

library LHelper {
    using LLocker for *;
    function calEP2PDBalance(
        uint fs_,
        uint booster_,
        uint totalP2UBalance_
    )
        internal
        pure
        returns(uint)
    {
       return fs_ * booster_ * totalP2UBalance_ / LPercentage.DEMIE2;
    }

    function calMintStakingPower(
        LLocker.SLock memory oldLockData,
        uint lockAmount_,
        uint lockTime_,
        bool isSelfStake_,
        uint selfStakeAdvantage_
    )
        internal
        view
        returns(uint)
    {
        uint rd = LLocker.restDuration(oldLockData);
        uint oldALock = oldLockData.amount;
        uint dLockForOldA = lockTime_;
        uint dLockForStakeA = lockTime_ + rd;
        if (lockTime_ == 0) {
            require(rd > 0, "already unlocked");
        }
        uint rs = (oldALock * calMultiplierForOldAmount(dLockForOldA) + lockAmount_ * calMultiplier(dLockForStakeA)) / LPercentage.DEMI;
        if (isSelfStake_) {
            rs = rs * selfStakeAdvantage_ / LPercentage.DEMI;
        }
        return rs;
    }


    function calBurnStakingPower(
        uint powerBalance_,
        uint unlockedA_,
        uint totalLockedA_
    )
        internal
        pure
        returns(uint)
    {
        return powerBalance_ * unlockedA_ / totalLockedA_;
    }

    function calFs(
        uint earningBalance_,
        uint maxEarning_
    )
        internal
        pure
        returns(uint)
    {
        uint max = maxEarning_;
        if (max < earningBalance_) {
            max = earningBalance_;
        }
        if (max == 0) {
            return LPercentage.DEMI;
        }
        return earningBalance_ * LPercentage.DEMI / max;
    }
    // with DEMI multiplied
    function calMultiplierForOldAmount(
        uint lockTime_
    )
        internal
        pure
        returns(uint)
    {
        uint x = lockTime_ * LPercentage.DEMI / 30 days;
        uint rs = (1300 * x / LPercentage.DEMI);
        return rs;
    }

    function calMultiplier(
        uint lockTime_
    )
        internal
        pure
        returns(uint)
    {
        uint x = lockTime_ * LPercentage.DEMI / 30 days;
        uint rs = (1300 * x / LPercentage.DEMI) + 8800;
        return rs;
    }

    function calAQuorum(
        uint aEthValue_,
        uint dEthValue_,
        uint voterPercent_,
        uint freezeDuration_,
        uint freezeDurationUnit_
    )
        internal
        pure
        returns(uint)
    {
        uint tmp = LPercentage.DEMI - voterPercent_;
        uint leverage = LPercentage.DEMIE2 *
            dEthValue_ * freezeDuration_ / aEthValue_ / freezeDurationUnit_ / tmp;
        if (leverage < LPercentage.DEMI) {
            leverage = LPercentage.DEMI;
        }
        return LPercentage.DEMI * leverage / (leverage + LPercentage.DEMI);
    }
}
