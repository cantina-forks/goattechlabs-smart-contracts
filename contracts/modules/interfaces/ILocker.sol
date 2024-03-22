// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "../../lib/LLocker.sol";

import "./ICashier.sol";

interface ILocker is ICashier {
    function initLocker(
        address accessControl_,
        address token_,
        address profileCAddr_,
        address penaltyAddress_
    )
        external;

    function lock(
        address account_,
        address poolOwner_,
        uint duration_
    )
        external;

    function withdraw(
        address account_,
        address poolOwner_,
        address dest_,
        uint amount_,
        bool isForced_
    )
        external;

    function penaltyAddress()
        external
        view
        returns(address);

    function getLockId(
        address account_,
        address poolOwner_
    )
        external
        pure
        returns(bytes32);

    function getLockDataById(
        bytes32 lockId_
    )
        external
        view
        returns(LLocker.SLock memory);

    function getLockData(
        address account_,
        address poolOwner_
    )
        external
        view
        returns(LLocker.SLock memory);
}
