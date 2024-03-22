// SPDX-License-Identifier: MIT

pragma solidity =0.8.8;
pragma abicoder v2;

import "./PERC20.sol";

import "./interfaces/IDistributor.sol";

contract DToken is PERC20 {
    mapping(uint => IDistributor) private _distributors;
    uint private _totalDistributors;

    function initDToken(
        address accessControl_,
        bool inPrivateMode_,
        string memory name_,
        string memory symbol_,
        address[] memory distributorAddrs_
    )
        public
        initializer
    {
        initPERC20(accessControl_, inPrivateMode_, name_, symbol_);
        _totalDistributors = distributorAddrs_.length;
        uint i = 0;
        uint n = _totalDistributors;
        while (i < n) {
            _distributors[i] = IDistributor(distributorAddrs_[i]);
            i++;
        }
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    )
        internal
        virtual
        override
    {
        uint i = 0;
        uint n = _totalDistributors;
        while (i < n) {
            _distributors[i].beforeTokenTransfer(from_, to_, amount_);
            i++;
        }
    }


    // function burn(
    //     address account_,
    //     uint amount_
    // )
    //     external
    //     override
    //     onlyAdmin
    // {
    //     uint i = 0;
    //     uint n = _totalDistributors;
    //     uint nextBalance = balanceOf(account_) - amount_;
    //     while (i < n) {
    //         _distributors[i].setReward(
    //             account_,
    //             _distributors[i].rewardOf(account_),
    //             nextBalance
    //         );
    //         i++;
    //     }
    //     super.burn(account_, amount_);
    // }
}
