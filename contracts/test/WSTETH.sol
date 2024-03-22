// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WSTETH is ERC20 {
    constructor(
        address mintTo_,
        uint mintA_
    )
        ERC20("TWSTETH", "TWSTETH")
    {
        _mint(mintTo_, mintA_);
    }
}