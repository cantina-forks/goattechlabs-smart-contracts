// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;

interface IPoolFactory {
    struct SPool{
        address dToken;
        address ethDistributor;
        address dctDistributor;
    }

    function initPoolFactory(
        address accessControl_,
        address geth_,
        address dct_
    )
        external;

    function createPool(
        address owner_
    )
        external;

    function isCreated(
        address owner_
    )
        external
        view
        returns(bool);

    function getPool(
        address owner_
    )
        external
        view
        returns(SPool memory);
}
