// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IAccessControl {
    function addAdmins(
        address[] memory accounts_
    )
        external;

    function removeAdmins(
        address[] memory accounts_
    )
        external;

    /*
        view
    */

    function isOwner(
        address account_
    )
        external
        returns(bool);

    function isAdmin(
        address account_
    )
        external
        view
        returns(bool);
}