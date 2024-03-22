// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IEthSharing {
    function initEthSharing(
        address accessControl_,
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_

    )
        external;

    function configSystem(
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_
    )
        external;

    function initPoolConfig(
        address poolOwner_
    )
        external
        returns(bool);

    function tryResetPool(
        address poolOwner_
    )
        external;

    function configPool(
        uint ownerPercent_,
        uint userPercent_ 
    )
        external;

    function getPoolLockPercent(
        address poolOwner_
    )
        external
        view
        returns(uint);

    function getDevTeamPart(
        uint value_
    )
        external
        view
        returns(uint);

    function getSysExcPart(
        uint value_
    )
        external
        view
        returns(uint);

    function getPoolOwnerPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getPoolUserPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getLockedPart(
        address poolOwner_,
        uint value_
    )
        external
        view
        returns(uint);

    function getSharingParts(
        address poolOwner_,
        uint value_,
        uint code_
    )
        external
        view
        returns(uint devTeamA, uint poolOwnerA, uint poolUserA, uint lockedA);
}