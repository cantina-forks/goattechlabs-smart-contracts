// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./IPERC20.sol";
import "./ICashier.sol";

interface IEarning is IPERC20, ICashier {
    function initEarning(
        address token_,
        address profileCAddr_,
        address accessControl_,
        string memory name_,
        string memory symbol_
    )
        external;

    function updateMaxEarning(
        address account_,
        uint maxEarning_
    )
        external;

    function shareCommission(
        address account_
    )
        external;

    function update(
        address account_,
        bool needShareComm_
    )
        external;

    function withdraw(
        address account_,
        uint amount_,
        address dest_
    )
        external;

    function earningOf(
        address account_
    )
        external
        view
        returns(uint);

    function maxEarningOf(
        address account_
    )
        external
        view
        returns(uint);
}