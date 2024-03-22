// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../modules/interfaces/IPERC20.sol";

interface IDCT is IPERC20 {
    function HALVING_INTERVAL()
        external
        view
        returns(uint);

    function initDCT(
        address accessControl_,
        address rewardPool_,
        address premineAddress_,
        uint256 premineAmount_,
        address cleanTo_
    )
        external;

    function tps()
        external
        view
        returns(uint);

    function pendingA()
        external
        view
        returns(uint);

    function publicMint()
        external;

    function lastMintAt()
        external
        view
        returns(uint);

    function lastHalved()
        external
        view
        returns(uint);

    function rewardPool()
        external
        view
        returns(address);
}
