// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

library LPercentage {
    uint constant public DEMI = 10000;
    uint constant public DEMIE2 = DEMI * DEMI;
    uint constant public DEMIE3 = DEMIE2 * DEMI;

    function validatePercent(
        uint percent_
    )
        internal
        pure
    {
        // 100% == DEMI == 10000
        require(percent_ <= DEMI, "invalid percent");
    }

    function getPercentA(
        uint value,
        uint percent
    )
        internal
        pure
        returns(uint)
    {
        return value * percent / DEMI;
    }
}