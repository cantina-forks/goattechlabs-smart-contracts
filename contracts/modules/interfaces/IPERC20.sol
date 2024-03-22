// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IATHBalance {
    function athBalance()
    external
    view
    returns(uint);
}

interface IPERC20 is IERC20, IATHBalance {
    function initPERC20(
        address owner_,
        bool inPrivateMode_,
        string memory name_,
        string memory symbol_
    )
        external;

    function setInPrivateMode(
        bool inPrivateMode_
    )
        external;

    function mint(
        address account_,
        uint amount_
    )
        external;

    function burn(
        address account_,
        uint amount_
    )
        external;

    function needAthRecord()
        external
        view
        returns(bool);

    function activeAthRecord()
        external;

    function deactiveAthRecord()
        external;
}