// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IProfile {
    struct SProfile{
        address sponsor;
        uint sPercent;
        uint nextSPercent;
        uint updatedAt;
        uint ifs;
        uint bonusBooster;
    }

    function updateSponsor(
        address account_,
        address sponsor_
    )
        external;

    function profileOf(
        address account_
    )
        external
        view
        returns(SProfile memory);

    function getSponsorPart(
        address account_,
        uint amount_
    )
        external
        view
        returns(address sponsor, uint sAmount);

    function setSPercent(
        uint sPercent_
    )
        external;

    function setDefaultSPercentConfig(
        uint sPercent_
    )
        external;

    function setMinSPercentConfig(
        uint sPercent_
    )
        external;

    function updateFsOf(
        address account_,
        uint fs_
    )
        external;

    function updateBoosterOf(
        address account_,
        uint booster_
    )
        external;

    function fsOf(
        address account_
    )
        external
        view
        returns(uint);

    function boosterOf(
        address account_
    )
        external
        view
        returns(uint);
}
