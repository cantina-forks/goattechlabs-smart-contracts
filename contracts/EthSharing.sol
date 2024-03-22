// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./lib/LPercentage.sol";

import "./modules/UseAccessControl.sol";

contract EthSharing is UseAccessControl {
    event ConfigSystem(
        uint devTeamPercent,
        uint defaultOwnerPercent,
        uint defaultUserPercent,
        uint defaultCode,
        bool inDefaultOnlyMode
    );

    event ConfigPool(
        address indexed poolOwner,
        SPoolConfig poolConfig
    );

    uint public devTeamPercent = 1 * 100;
    uint public defaultOwnerPercent = 2 * 100;
    uint public defaultUserPercent = 3 * 100;
    uint public defaultCode = getCode(defaultOwnerPercent, defaultUserPercent);

    bool public inDefaultOnlyMode;

    struct SPoolConfig {
        uint ownerPercent;
        uint userPercent;
        uint code;
        bool isInitialized;
    }

    mapping(address => SPoolConfig) public poolConfigOf;

    function initEthSharing(
        address accessControl_,
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_

    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);
        _configSystem(
            devTeamPercent_,
            defaultOwnerPercent_,
            defaultUserPercent_,
            inDefaultOnlyMode_
        );
    }

    function getCode(
        uint ownerPercent_,
        uint userPercent_
    )
        public
        pure
        returns(uint)
    {
        return ownerPercent_ * LPercentage.DEMI + userPercent_;
    }

    function getPoolCode(
        address poolOwner_
    )
        public
        view
        returns(uint)
    {
        SPoolConfig storage poolConfig = poolConfigOf[poolOwner_];
        return poolConfig.code;
    }

    function _configPool(
        address poolOwner_,
        uint ownerPercent_,
        uint userPercent_
    )
        internal
    {
       LPercentage.validatePercent(ownerPercent_ + userPercent_);
       SPoolConfig storage poolConfig = poolConfigOf[poolOwner_];
       poolConfig.isInitialized = true;
       poolConfig.ownerPercent = ownerPercent_;
       poolConfig.userPercent = userPercent_;
       poolConfig.code = getCode(ownerPercent_, userPercent_);
       emit ConfigPool(poolOwner_, poolConfig);
    }

    function _configSystem(
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_
    )
        internal
    {
        require(devTeamPercent_ < 5 * 100, "too much for devTeam");

        devTeamPercent = devTeamPercent_;
        defaultOwnerPercent = defaultOwnerPercent_;
        defaultUserPercent = defaultUserPercent_;
        defaultCode = getCode(defaultOwnerPercent_, defaultUserPercent_);

        inDefaultOnlyMode = inDefaultOnlyMode_;
        emit ConfigSystem(
            devTeamPercent_,
            defaultOwnerPercent_,
            defaultUserPercent_,
            defaultCode,
            inDefaultOnlyMode_
        );
    }

    function configSystem(
        uint devTeamPercent_,
        uint defaultOwnerPercent_,
        uint defaultUserPercent_,
        bool inDefaultOnlyMode_
    )
        external
        onlyAdmin
    {
        _configSystem(
            devTeamPercent_,
            defaultOwnerPercent_,
            defaultUserPercent_,
            inDefaultOnlyMode_
        );
    }

    function tryResetPool(
        address poolOwner_
    )
        external
        onlyAdmin
    {
        if (inDefaultOnlyMode && (poolConfigOf[poolOwner_].code != defaultCode)) {
            _configPool(poolOwner_, defaultOwnerPercent, defaultUserPercent);
        }
    }

    function initPoolConfig(
        address poolOwner_
    )
        external
        onlyAdmin
        returns(bool)
    {
        SPoolConfig storage poolConfig = poolConfigOf[poolOwner_];
        if (poolConfig.isInitialized) {
            return false;
        }
        _configPool(poolOwner_, defaultOwnerPercent, defaultUserPercent);
        return true;
    }

    function configPool(
        uint ownerPercent_,
        uint userPercent_
    )
        external
    {
        require(!inDefaultOnlyMode, "inDefaultOnlyMode enabled");
        _configPool(msg.sender, ownerPercent_, userPercent_);
    }

    function getPoolLockPercent(
        address poolOwner_
    )
        public
        view
        returns(uint)
    {
        SPoolConfig memory poolConfig = poolConfigOf[poolOwner_];
        return LPercentage.DEMI - poolConfig.ownerPercent - poolConfig.userPercent;
    }

    function getDevTeamPart(
        uint value_
    )
        public
        view
        returns(uint)
    {
        uint amount = LPercentage.getPercentA(value_, devTeamPercent);
        return amount;
    }

    function getSysExcPart(
        uint value_
    )
        public
        view
        returns(uint)
    {
        uint amount = value_ - getDevTeamPart(value_);
        return amount;
    }

    function getPoolOwnerPart(
        address poolOwner_,
        uint value_
    )
        public
        view
        returns(uint)
    {
        uint sysExcPart = getSysExcPart(value_);
        SPoolConfig memory poolConfig = poolConfigOf[poolOwner_];
        uint amount = LPercentage.getPercentA(sysExcPart, poolConfig.ownerPercent);
        return amount;
    }

    function getPoolUserPart(
        address poolOwner_,
        uint value_
    )
        public
        view
        returns(uint)
    {
        uint sysExcPart = getSysExcPart(value_);
        SPoolConfig memory poolConfig = poolConfigOf[poolOwner_];
        uint amount = LPercentage.getPercentA(sysExcPart, poolConfig.userPercent);
        return amount;
    }

    function getLockedPart(
        address poolOwner_,
        uint value_
    )
        public
        view
        returns(uint)
    {
        uint sysExcPart = getSysExcPart(value_);
        uint amount = sysExcPart
            - getPoolOwnerPart(poolOwner_, value_)
            - getPoolUserPart(poolOwner_, value_);
        return amount;
    }

    function getSharingParts(
        address poolOwner_,
        uint value_,
        uint code_
    )
        public
        view
        returns(uint devTeamA, uint poolOwnerA, uint poolUserA, uint lockedA)
    {
        require(code_ == getPoolCode(poolOwner_), "invalid config code");
        devTeamA = getDevTeamPart(value_);
        poolOwnerA = getPoolOwnerPart(poolOwner_, value_);
        poolUserA = getPoolUserPart(poolOwner_, value_);
        lockedA = value_ - devTeamA - poolOwnerA - poolUserA;
    }
}
