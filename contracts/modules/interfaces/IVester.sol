// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../../lib/LLocker.sol";

import "./ICashier.sol";

interface IVester is ICashier {
    function initVester(
        address accessControl_,
        address token_,
        address cleanTo_
    )
        external;

    function lock(
        address account_,
        uint duration_,
        uint cliff_
    )
        external;

    function transferLock(
        address from_,
        address to_,
        uint amount_
    )
        external;

    function unlock(
        address account_
    )
        external;

    function currentLockData(
        address account_
    )
        external
        view
        returns(uint restA, uint restDuration);

    function getUnlockedA(
        address account_
    )
        external
        view
        returns(uint);

    function getLockData(
        address account_
    )
        external
        view
        returns(LLocker.SLock memory);
}