// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./modules/UseAccessControl.sol";
import "./interfaces/IProfile.sol";

import "./lib/LPercentage.sol";
import "./lib/LProfile.sol";

contract Profile is IProfile, UseAccessControl {
    using LPercentage for *;
    using LProfile for *;

    event UpdateSponsor(
        address indexed account,
        address indexed sponsor,
        uint sPercent
    );

    event SetSPercent(
        address indexed account,
        uint sPercent
    );

    event UpdateFsOf(
        address indexed account,
        uint fs
    );

    event UpdateBoosterOf(
        address indexed account,
        uint booster
    );

    mapping(address => SProfile) private _profileOf;
    uint public _defaultSPercent = 1000; // 10%
    uint public _minSPercent = 1000; // 10%

    function initProfile(
        address accessControl_
    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);
    }

    function _updateSponsor(
        address account_,
        address sponsor_
    )
        internal
    {
        require(sponsor_ != address(0x0), "invalid sponsor");
        SProfile storage profileData = _profileOf[account_];
        if (profileData.sponsor == address(0x0)) {
            _initDefaultSPercent(account_);
        }
        profileData.sponsor = sponsor_;
        profileData.sPercent = profileData.nextSPercent;
        profileData.updatedAt = block.timestamp;
        emit UpdateSponsor(account_, sponsor_, profileData.sPercent);
    }

    function updateSponsor(
        address account_,
        address sponsor_
    )
        external
        onlyAdmin
    {
        _updateSponsor(account_, sponsor_);
    }

    function setSPercent(
        uint sPercent_
    )
        external
    {
        address account = msg.sender;
        LPercentage.validatePercent(sPercent_);
        require(sPercent_ >= _minSPercent, "sPercent_ invalid");
        SProfile storage profileData = _profileOf[account];
        profileData.nextSPercent = sPercent_;
        if (sPercent_ >  profileData.sPercent) {
            _updateSponsor(account, profileData.sponsor);
        }
        emit SetSPercent(account, sPercent_);
    }

    function _initDefaultSPercent(
        address account_
    )
        internal
    {
        SProfile storage profileData = _profileOf[account_];
        profileData.nextSPercent = _defaultSPercent;
        emit SetSPercent(account_, _defaultSPercent);
    }

    function setDefaultSPercentConfig(
        uint sPercent_
    )
        external
        onlyAdmin
    {
        LPercentage.validatePercent(sPercent_);
        _defaultSPercent = sPercent_;
    }

    function setMinSPercentConfig(
        uint sPercent_
    )
        external
        onlyAdmin
    {
        LPercentage.validatePercent(sPercent_);
        _minSPercent = sPercent_;
    }

    function updateFsOf(
        address account_,
        uint fs_
    )
        external
        onlyAdmin
    {
        SProfile storage profileData = _profileOf[account_];
        profileData.ifs = LProfile.invertOf(fs_);
        emit UpdateFsOf(account_, fs_);
    }

    function updateBoosterOf(
        address account_,
        uint booster_
    )
        external
        onlyAdmin
    {
        SProfile storage profileData = _profileOf[account_];
        profileData.bonusBooster = booster_ - LPercentage.DEMI;
        emit UpdateBoosterOf(account_, booster_);
    }

    function profileOf(
        address account_
    )
        external
        view
        returns(SProfile memory)
    {
        return _profileOf[account_];
    }

    function getSponsorPart(
        address account_,
        uint amount_
    )
        external
        view
        returns(address sponsor, uint sAmount)
    {
        SProfile memory profileData = _profileOf[account_];
        sponsor = profileData.sponsor;
        if (sponsor != address(0x0)) {
            sAmount = LPercentage.getPercentA(amount_, profileData.sPercent);
        } else {
            sAmount = 0;
        }
    }

    function fsOf(
        address account_
    )
        external
        view
        returns(uint)
    {
        SProfile memory profileData = _profileOf[account_];
        return LProfile.invertOf(profileData.ifs);
    }

    function boosterOf(
        address account_
    )
        external
        view
        returns(uint)
    {
        SProfile memory profileData = _profileOf[account_];
        return LPercentage.DEMI + profileData.bonusBooster;
    }
}
