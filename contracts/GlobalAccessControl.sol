// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./modules/AccessControl.sol";

contract GlobalAccessControl is AccessControl {
    constructor() {
        _transferOwnership(msg.sender);
    }
}
