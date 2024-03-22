// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./modules/UseAccessControl.sol";
import "./modules/Vester.sol";

contract DCT is ERC20, UseAccessControl {
    uint private _tps = 7 ether;

    uint private _lastMintAt;
    uint private _lastHalved;
    uint constant public HALVING_INTERVAL = 7 days;

    address private _rewardPool;

    uint private _athBalance;

    Vester private _vester;

    uint constant public MAX_SUPPLY = 3111666666 ether;
    bool public isMintingFinished = false;

    constructor() ERC20("GOAT", "GOAT") {}

    function initDCT(
        address accessControl_,
        address rewardPool_,
        address premineAddress_,
        uint256 premineAmount_,
        address cleanTo_
    )
        external
        initializer
    {
        initUseAccessControl(accessControl_);

        _rewardPool = rewardPool_;
        _vester = new Vester();
        _vester.initVester(accessControl_, address(this), cleanTo_);

        _mint(premineAddress_, premineAmount_);
    }

    function start()
        external
        onlyOwner
    {
        require(_lastMintAt == 0, "already started");
        _lastMintAt = block.timestamp;
        _lastHalved = block.timestamp;
    }

    function _beforeTokenTransfer(
        address from_,
        address,
        uint256
    )
        internal
        virtual
        override
    {
        if (msg.sender != address(_vester)) {
           _vester.unlock(from_);
        }
    }

    function tps()
        external
        view
        returns(uint)
    {
        return _tps;
    }

    function pendingA()
        public
        view
        returns(uint)
    {
        if (isMintingFinished || _lastMintAt == 0) {
            return 0;
        }
        uint pastTime = block.timestamp - _lastMintAt;
        return _tps * pastTime;
    }

    function publicMint()
        external
    {
        uint mintingA = pendingA();
        if (mintingA == 0) {
            return;
        }
        if (totalSupply() + mintingA > MAX_SUPPLY) {
            isMintingFinished = true;
            return;
        }
        _mint(_rewardPool, mintingA);
        _lastMintAt = block.timestamp;
        if (block.timestamp - _lastHalved >= HALVING_INTERVAL) {
            _tps = _tps / 2;
            _lastHalved = block.timestamp;
        }
    }

    function lastMintAt()
        external
        view
        returns(uint)
    {
        return _lastMintAt;
    }

    function lastHalved()
        external
        view
        returns(uint)
    {
        return _lastHalved;
    }

    function rewardPool()
        external
        view
        returns(address)
    {
        return _rewardPool;
    }

    function vester()
        external
        view
        returns(address)
    {
        return address(_vester);
    }

    function balanceOf(address account_) public view override returns (uint256) {
        return super.balanceOf(account_) + _vester.getUnlockedA(account_);
    }

    function changeRewardPool(
        address rewardPool_
    )
        external
        onlyAdmin
    {
        _rewardPool = rewardPool_;
    }
}
