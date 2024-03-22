// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./modules/UseAccessControl.sol";

import "./modules/DToken.sol";
import "./modules/Distributor.sol";

import "./modules/interfaces/IDToken.sol";
import "./modules/interfaces/IDistributor.sol";

import "./interfaces/IPoolFactory.sol";


contract PoolFactory is IPoolFactory, UseAccessControl {
    event CreatePool(
        address indexed owner,
        SPool pool
    );

    bytes private _dTokenBytecode;
    bytes private _distributorBytecode;

    bool private _inPrivateMode = true;
    string constant private DIV_TOKEN_NAME = "P2U Dividend Token";
    string constant private DIV_TOKEN_SYMBOL = "P2U";

    address private _geth;
    address private _dct;

    mapping(address => bool) private _isCreated;
    mapping(address => SPool) private _pools;

    function initPoolFactory(
        address accessControl_,
        address geth_,
        address dct_
    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);
        _geth = geth_;
        _dct = dct_;
        _dTokenBytecode = type(DToken).creationCode;
        _distributorBytecode = type(Distributor).creationCode;
    }

    function _deploy(
        bytes memory bytecode,
        uint _salt
    )
        internal
        returns(address addr)
    {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function _createPool(
        address owner_
    )
        internal
    {
        require(!_isCreated[owner_], "already created");
        _isCreated[owner_] = true;

        uint salt = uint256(uint160(owner_));
        SPool storage pool = _pools[owner_];
        pool.dToken = _deploy(_dTokenBytecode, salt);
        pool.ethDistributor = _deploy(_distributorBytecode, salt);
        pool.dctDistributor = _deploy(_distributorBytecode, salt + 1);

        address[] memory poolDistributorAddrs = new address[](2);
        poolDistributorAddrs[0] = pool.ethDistributor;
        poolDistributorAddrs[1] = pool.dctDistributor;
        IDToken(pool.dToken).initDToken(
            address(_accessControl),
            _inPrivateMode,
            DIV_TOKEN_NAME,
            DIV_TOKEN_SYMBOL,
            poolDistributorAddrs
        );

        IDistributor(pool.ethDistributor).initDistributor(
            address(_accessControl),
            pool.dToken,
            _geth
        );

        IDistributor(pool.dctDistributor).initDistributor(
            address(_accessControl),
            pool.dToken,
            _dct
        );
        emit CreatePool(owner_, pool);
    }

    function createPool(
        address owner_
    )
        external
        onlyAdmin
    {
        require(!isContract(owner_), "owner cannot be a contract");
        _createPool(owner_);
    }

    function isCreated(
        address owner_
    )
        external
        view
        returns(bool)
    {
        return _isCreated[owner_];
    }

    function getPool(
        address owner_
    )
        external
        view
        returns(SPool memory)
    {
        return _pools[owner_];
    }

    function isContract(address _addr) private view returns (bool){
    uint32 size;
    assembly {
        size := extcodesize(_addr)
    }
    return (size > 0);
    }
}
