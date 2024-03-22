// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "./LPercentage.sol";

library LProfile {
    // fs: Financial_stability
    // invert fs: ifs = 1 - fs
    // multiplied DEMI = 10000

    function invertOf(
        uint value_
    )
        internal
        pure
        returns(uint)
    {
        return LPercentage.DEMI - value_;
    }

    function calBooster(
        uint boostVotePower_,
        uint maxBoostVotePower_,
        uint maxBooster_
    )
        pure
        internal
        returns(uint)
    {
        uint max = boostVotePower_ > maxBoostVotePower_ ? boostVotePower_ : maxBoostVotePower_;
        if (max == 0) {
            return LPercentage.DEMI;
        }
        return LPercentage.DEMI + LPercentage.DEMI * (maxBooster_ - 1) * boostVotePower_ / max;
    }
}
