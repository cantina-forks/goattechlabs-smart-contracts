// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

import "./ICashier.sol";

interface IDistributor is ICashier {
    function initDistributor(
        address accessControl_,
        address dToken_,
        address rewardToken_
    )
        external;

    function beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    )
        external;

    function distribute()
        external;

    function rewardOf(
        address account_
    )
        external
        view
        returns(uint);

    function claimFor(
        address account_,
        address dest_
    )
        external;        
}