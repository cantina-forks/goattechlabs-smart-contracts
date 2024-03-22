// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./IPERC20.sol";

interface IDToken is IPERC20 {
    function initDToken(
        address accessControl_,
        bool inPrivateMode_,
        string memory name_,
        string memory symbol_,
        address[] memory distributorAddrs_
    )
        external;
}