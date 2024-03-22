// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
pragma abicoder v2;

import "./lib/LPercentage.sol";
import "./lib/LLocker.sol";
import "./lib/LProfile.sol";
import "./lib/LHelper.sol";
import "./lib/LLido.sol";

import "./modules/UseAccessControl.sol";
import "./modules/interfaces/IDToken.sol";
import "./modules/interfaces/IDistributor.sol";
import "./modules/interfaces/ILocker.sol";
import "./modules/interfaces/IEarning.sol";

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IProfile.sol";
import "./interfaces/IDCT.sol";
import "./interfaces/IVoting.sol";
import "./interfaces/IEthSharing.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Controller is UseAccessControl {
    using LPercentage for *;
    using LProfile for *;

    modifier tryPublicMint() {
        if (block.timestamp - _lastMintAt > _mintingInt) {
            _lastMintAt = block.timestamp;
            _dct.publicMint();
        }
        _;
    }

    event Stake(
        bool indexed isEth,
        address indexed poolOwner,
        address indexed staker,
        uint amount,
        uint duration,
        uint powerMinted,
        bool isFirstStake // for eth only
    );

    event AdminUpdateConfig(
        uint[] values
    );

    string constant public VERSION = "DEV";

    IERC20 private _geth;
    IDCT private _dct;

    IDistributor private _devTeam;
    IPoolFactory private _poolFactory;
    IProfile private _profileC;

    ILocker private _eLocker;
    IDToken private _eP2PDToken;
    // IDistributor private _eP2PDistributor;
    IEarning private _eEarning;

    ILocker private _dLocker;
    IDToken private _dP2PDToken;
    IDistributor private _dP2PDistributor;
    IEarning private _dEarning;

    IVoting private _voting;

    IDistributor private _eDP2PDistributor;
    IDistributor private _dDP2PDistributor;

    IEthSharing private _ethSharing;

    uint public _maxBooster = 2;

    uint public _minDuration = 30 days;
    uint public _maxDuration = 720 days;
    uint public _minStakeETHAmount = 0.001e18;
    uint public _minStakeDCTAmount = 7 ether;

    uint public _maxSponsorAdv = 7;
    uint public _maxSponsorAfter = 7 days;

    uint public _lastMintAt;
    uint public _mintingInt = 7;

    uint public _attackFee = 1 ether;
    uint public _minFreezeDuration = 1 days;
    uint public _maxFreezeDuration = 7 days;
    uint public _freezeDurationUnit = 7 days;
    uint public _minDefenderFund = 0.001e18;

    uint public _maxVoterPercent = 5000; //50%
    uint public _minAttackerFundRate = 2500; //25%

    uint public _bountyPullEarningPercent = 100; //1%

    uint public _selfStakeAdvantage = 15000; // 150%

    uint public _isPausedAttack = 0;

    uint public _dctTaxPercent = 100;

    receive() external payable {}

    function initController(
        address[] memory contracts_
    )
        external
        initializer
    {
        _geth = IERC20(contracts_[0]);
        _dct = IDCT(contracts_[1]);

        initUseAccessControl(contracts_[2]);
        _devTeam = IDistributor(contracts_[3]);
        _poolFactory = IPoolFactory(contracts_[4]);
        _profileC = IProfile(contracts_[5]);

        _eLocker = ILocker(contracts_[6]);
        _eP2PDToken = IDToken(contracts_[7]);
        // _eP2PDistributor = IDistributor(contracts_[8]);
        _eEarning = IEarning(contracts_[8]);

        _dLocker = ILocker(contracts_[9]);
        _dP2PDToken = IDToken(contracts_[10]);
        _dP2PDistributor = IDistributor(contracts_[11]);
        _dEarning = IEarning(contracts_[12]);

        _voting = IVoting(contracts_[13]);

        //airdrop ETH by dP2PDToken
        _eDP2PDistributor = IDistributor(contracts_[14]);
        //airdrop DCT by dP2PDToken
        _dDP2PDistributor = IDistributor(contracts_[15]);

        // note
        // add ethSharing in initController
        _ethSharing = IEthSharing(contracts_[16]);

        _dP2PDToken.activeAthRecord();
    }

    //call after update Fs, booster, or P2uDToken Balance
    function _reCalEP2PDBalance(
        address poolOwner_
    )
        internal
    {
        if (_poolFactory.isCreated(poolOwner_)) {
            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);

            uint oldEP2PBalance = _eP2PDToken.balanceOf(pool.dctDistributor);

            uint newEP2PBalance = LHelper.calEP2PDBalance(
                _profileC.fsOf(poolOwner_),
                _profileC.boosterOf(poolOwner_),
                p2UDtoken.totalSupply()
            );
            if (newEP2PBalance > oldEP2PBalance) {
                _eP2PDToken.mint(pool.dctDistributor, newEP2PBalance - oldEP2PBalance);
            } else if (newEP2PBalance < oldEP2PBalance) {
                _eP2PDToken.burn(pool.dctDistributor, oldEP2PBalance - newEP2PBalance);
            }
        }
    }

    // call after update ETH earning balance
    function _reCalFs(
        address account_
    )
        internal
    {
        uint maxEarning = _eEarning.maxEarningOf(account_);
        _profileC.updateFsOf(account_, LHelper.calFs(
            _eEarning.balanceOf(account_) + _voting.defenderEarningFreezedOf(account_),
            maxEarning
        ));
        _reCalEP2PDBalance(account_);
    }

    //call after update dP2pDtoken balance
    function _reCalBooster(
        address account_
    )
        internal
    {
        uint maxBoostVotePower = _dP2PDToken.athBalance();
        uint boostVotePower = _dP2PDToken.balanceOf(account_);
        uint newBooster = LProfile.calBooster(boostVotePower, maxBoostVotePower, _maxBooster);
        _profileC.updateBoosterOf(account_, newBooster);
    }

    // eth only
    function _updateSponsor(
        address payable poolOwner_,
        address staker_,
        uint minSPercent_
    )
        internal
    {
        if (poolOwner_ == staker_) {
            return;
        }
        IProfile.SProfile memory profile = _profileC.profileOf(poolOwner_);
        if (profile.sponsor == staker_) {
            return;
        }
        require(profile.nextSPercent >= minSPercent_, "profile rate changed");
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        IDToken p2UDtoken = IDToken(pool.dToken);
        uint timeDiff = block.timestamp - profile.updatedAt;
        if (timeDiff > _maxSponsorAfter) {
            timeDiff = _maxSponsorAfter;
        }

        uint sponsorDTokenBalance = p2UDtoken.balanceOf(profile.sponsor);
        uint stakerDTokenBalance = p2UDtoken.balanceOf(staker_);
        uint sponsorBonus = sponsorDTokenBalance * (_maxSponsorAdv - 1)
            * timeDiff / _maxSponsorAfter;
        uint sponsorPower = sponsorDTokenBalance + sponsorBonus;
        if (stakerDTokenBalance > sponsorPower || poolOwner_ == profile.sponsor) {
            address[] memory pools = new address[](1);
            pools[0] = poolOwner_;
            earningPulls(poolOwner_, pools, poolOwner_);
            _profileC.updateSponsor(poolOwner_, staker_);
        }
    }

    // eth only
    function _shareDevTeam(
        uint amount_
    )
        internal
    {
        _geth.transfer(address(_devTeam), amount_);
    }

    // eth only
    function _sharePoolOwner(
        uint amount_,
        address payable poolOwner_
    )
        internal
    {
        _eEarning.clean();

        _geth.transfer(address(_eEarning), amount_);

        _eEarning.update(poolOwner_, true);
    }

    // eth only
    function _sharePoolUser(
        uint amount_,
        address payable poolOwner_
    )
        internal
    {
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        _geth.transfer(pool.ethDistributor, amount_);
    }

    function _lock(
        bool isEth_,
        address payable poolOwner_,
        uint duration_
    )
        internal
        returns (uint)
    {

        if (isEth_) {
            uint value = _geth.balanceOf(address(this));
            _eLocker.clean();
            _geth.transfer(address(_eLocker), value);
            _eLocker.lock(msg.sender, poolOwner_, duration_);

            return value;
        } else {
            uint value = _dct.balanceOf(address(this));
            _dLocker.clean();
            _dct.transfer(address(_dLocker), value);
            _dLocker.lock(msg.sender, poolOwner_, duration_);

            return value;
        }
    }

    function _stake(
        bool isEth_,
        address account_,
        address payable poolOwner_,
        uint duration_,
        uint minSPercent_,
        uint poolConfigCode_
    )
        internal
    {
        if (isEth_) {
            if (!_poolFactory.isCreated(account_)) {
                _poolFactory.createPool(account_);
                _ethSharing.initPoolConfig(account_);

                if (account_ == poolOwner_) {
                    // first stake self
                    _profileC.updateSponsor(account_, account_);
                } else {
                    // first stake other
                    _profileC.updateSponsor(account_, address(_devTeam));
                }
            }
            require(_poolFactory.isCreated(poolOwner_), "not activated");
        }

        // if (address(this).balance > 0) {
        //     require(isEth_, "is not eth staking");
        //     _weth.deposit{value: address(this).balance}();
        // }
        uint value = isEth_ ? _geth.balanceOf(address(this)) : _dct.balanceOf(address(this));
        ILocker locker = isEth_ ? _eLocker : _dLocker;
        uint minStakeAmount = isEth_ ? _minStakeETHAmount : _minStakeDCTAmount;

        LLocker.SLock memory oldLockData = locker.getLockData(account_, poolOwner_);

        {
        require(value == 0 || value >= minStakeAmount, "amount too small");
        require(duration_ == 0 || duration_ >= _minDuration, "duration too small");

        uint rd = LLocker.restDuration(oldLockData);
        if (rd + duration_ > _maxDuration) {
            duration_ = _maxDuration - rd;
        }
        }

        uint powerMinted;
        if (isEth_) {
            {
            _ethSharing.tryResetPool(poolOwner_);
            (uint devTeamA, uint poolOwnerA, uint poolUserA, ) =
                _ethSharing.getSharingParts(poolOwner_, value, poolConfigCode_);
            _shareDevTeam(devTeamA);
            _sharePoolOwner(poolOwnerA, poolOwner_);
            _sharePoolUser(poolUserA, poolOwner_);
            }
            {
            uint aLock = _lock(isEth_, poolOwner_, duration_);

            powerMinted = LHelper.calMintStakingPower(
                oldLockData,
                aLock,
                duration_,
                account_ == poolOwner_,
                _selfStakeAdvantage
            );
            }
            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);
            bool isFirstStake = p2UDtoken.totalSupply() == 0;
            p2UDtoken.mint(account_, powerMinted);
            if (isFirstStake) {
                IDistributor(pool.ethDistributor).distribute();
            }

            _updateSponsor(poolOwner_, account_, minSPercent_);
            emit Stake(isEth_, poolOwner_, account_, value, duration_, powerMinted, isFirstStake);
        } else {
            {
            require(account_ == poolOwner_, "can only stake DCT for yourself");
            uint aLock = _lock(isEth_, poolOwner_, duration_);

            powerMinted = LHelper.calMintStakingPower(
                oldLockData,
                aLock,
                duration_,
                false,
                _selfStakeAdvantage
            );
            }
            _dP2PDToken.mint(poolOwner_, powerMinted);
            emit Stake(isEth_, poolOwner_, account_, value, duration_, powerMinted, false);
        }

        _reCalBooster(poolOwner_);
        _reCalFs(poolOwner_);


        /*
            debug only
        */
        // require(address(this).balance == 0, "not empty eth");
        // require(_geth.balanceOf(address(this)) == 0, "not empty eth");
        // require(_dct.balanceOf(address(this)) == 0, "not empty dct");
    }

    function _prepareWsteth(
        uint minWstethA_,
        uint wstethA_
    )
        internal
    {
        if (minWstethA_ > 0) {
            LLido.allToWsteth(minWstethA_);
        }
        if (wstethA_ > 0) {
            _geth.transferFrom(msg.sender, address(this), wstethA_);
        }
    }

    function ethStake(
        address payable poolOwner_,
        uint duration_,
        uint minSPercent_,
        uint poolConfigCode_,
        uint minWstethA_,
        uint wstethA_
    )
        public
        payable
        tryPublicMint
    {
        bool isEth = true;
        _prepareWsteth(minWstethA_, wstethA_);
        _stake(isEth, msg.sender, poolOwner_, duration_, minSPercent_, poolConfigCode_);
    }

    function dctStake(
        uint amount_,
        address payable poolOwner_,
        uint duration_
    )
        public
        payable
        tryPublicMint
    {
        _dct.transferFrom(msg.sender, address(this), amount_);
        uint taxA = LPercentage.getPercentA(amount_, _dctTaxPercent);
        _dct.transfer(address(0xdead), taxA);
        bool isEth = false;
        // any
        uint poolConfigCode = 0;
        _stake(isEth, msg.sender, poolOwner_, duration_, 0, poolConfigCode);
    }

    function _distributorClaimFor(
        address distributor_,
        address account_,
        address dest_
    )
        internal
    {
        IDistributor(distributor_).distribute();
        IDistributor(distributor_).claimFor(account_, dest_);
    }

    function _earningPull(
        address account_,
        address poolOwner_
    )
        internal
    {
        IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
        // _eP2PDistributor.claimFor(pool.ethDistributor, pool.ethDistributor);
        _dP2PDistributor.claimFor(pool.dctDistributor, pool.dctDistributor);

        // IDistributor(pool.dctDistributor).distribute();
        // IDistributor(pool.ethDistributor).distribute();

        // IDistributor(pool.dctDistributor).claimFor(account_, address(_dEarning));
        // IDistributor(pool.ethDistributor).claimFor(account_, address(this));

        _distributorClaimFor(pool.dctDistributor, account_, address(_dEarning));
        _distributorClaimFor(pool.ethDistributor, account_, address(this));
    }

    function earningPulls(
        address account_,
        address[] memory poolOwners_,
        address bountyPullerTo_
    )
        public
        tryPublicMint
    {
        _dEarning.clean();
        _eEarning.clean();

        // _eP2PDistributor.distribute();
        _dP2PDistributor.distribute();

        // _eDP2PDistributor.distribute();
        // _dDP2PDistributor.distribute();

        // _eDP2PDistributor.claimFor(account_, address(this));
        // _dDP2PDistributor.claimFor(account_, address(_dEarning));

        _distributorClaimFor(address(_eDP2PDistributor), account_, address(this));
        _distributorClaimFor(address(_dDP2PDistributor), account_, address(_dEarning));

        for(uint i = 0; i < poolOwners_.length; i++) {
            _earningPull(account_, poolOwners_[i]);
        }

        if (bountyPullerTo_ == account_) {
            _geth.transfer(address(_eEarning), _geth.balanceOf(address(this)));
        } else {
            uint256 amountForPuller = _geth.balanceOf(address(this)) * _bountyPullEarningPercent / LPercentage.DEMI;

            LLido.sellWsteth(amountForPuller);
            LLido.wethToEth();
            payable(bountyPullerTo_).transfer(address(this).balance);

            _geth.transfer(address(_eEarning), _geth.balanceOf(address(this)));
        }

        _dEarning.update(account_, true);
        _eEarning.update(account_, true);

        _reCalFs(account_);
    }

    /*
        UNLOCK: REINVEST/WITHDRAW
    */

    // function lockReinvest(
    //     bool isEth_,
    //     address payable poolOwner_,
    //     address payable toPoolOwner_,
    //     uint duration_,
    //     bool isPoolCreated_,
    //     uint amount_,
    //     uint minSPercent_,
    //     uint minEthA_
    // )
    //     external
    // {
    //     lockWithdraw(isEth_, poolOwner_, amount_, payable(address(this)), minEthA_);
    //     address account = msg.sender;
    //     _stake(isEth_, account, toPoolOwner_, duration_, isPoolCreated_, minSPercent_);
    // }

    function lockWithdraw(
        bool isEth_,
        address payable poolOwner_,
        uint amount_,
        address payable dest_,
        bool isForced_,
        uint minEthA_
    )
        public
        tryPublicMint
    {
        address account = msg.sender;
        ILocker locker = isEth_ ? _eLocker : _dLocker;

        LLocker.SLock memory oldLockData = locker.getLockData(account, poolOwner_);
        locker.withdraw(account, poolOwner_, address(this), amount_, isForced_);
        uint restAmount = oldLockData.amount - amount_;

        // burn
        if (isEth_) {
            require(restAmount == 0 || restAmount >= _minStakeETHAmount, "rest amount too small");

            IPoolFactory.SPool memory pool = _poolFactory.getPool(poolOwner_);
            IDToken p2UDtoken = IDToken(pool.dToken);
            uint burnedPower = LHelper.calBurnStakingPower(p2UDtoken.balanceOf(account), amount_, oldLockData.amount);
            p2UDtoken.burn(account, burnedPower);

            _reCalEP2PDBalance(poolOwner_);
            LLido.allToEth(minEthA_);
            // _weth.withdraw(_weth.balanceOf(address(this)));
            dest_.transfer(address(this).balance);
        } else {
            require(restAmount == 0 || restAmount >= _minStakeDCTAmount, "rest amount too small");

            uint burnedPower = LHelper.calBurnStakingPower(_dP2PDToken.balanceOf(poolOwner_), amount_, oldLockData.amount);
            _dP2PDToken.burn(poolOwner_, burnedPower);

            _reCalBooster(poolOwner_);
            _reCalEP2PDBalance(poolOwner_);

            _dct.transfer(dest_, _dct.balanceOf(address(this)));
        }
    }

    // EARNING: REINVEST/WITHDRAW

    function earningReinvest(
        bool isEth_,
        address payable poolOwner_,
        uint duration_,
        uint amount_,
        // address[] memory pulledPoolOwners_,
        uint minSPercent_,
        uint poolConfigCode_
    )
        external
    {
        address account = msg.sender;
        if (isEth_) {
            LLocker.SLock memory oldLockData = _eLocker.getLockData(account, poolOwner_);
            uint realDuration = duration_ + LLocker.restDuration(oldLockData);
            if (realDuration > _maxDuration) {
                realDuration = _maxDuration;
            }
            uint maxEarning = _eEarning.maxEarningOf(account);
            maxEarning -= amount_ * realDuration / _maxDuration;
            _eEarning.updateMaxEarning(account, maxEarning);
        }
         earningWithdraw(isEth_, amount_, payable(address(this)), 0);
        _stake(isEth_, account, poolOwner_, duration_, minSPercent_, poolConfigCode_);
    }

    function earningWithdraw(
        bool isEth_,
        uint amount_,
        address payable dest_,
        uint minEthA_
        // address[] memory pulledPoolOwners_
    )
        public
    {
        address account = msg.sender;
        // earningPulls(account, pulledPoolOwners_, account);
        IEarning earning = isEth_ ? _eEarning : _dEarning;

        earning.withdraw(account, amount_, address(this));
        //burn
        if (isEth_) {
            _reCalFs(account);
            if (dest_ != address(this)) {
                LLido.allToEth(minEthA_);
                dest_.transfer(address(this).balance);
            }
        } else {
            _dct.transfer(dest_, _dct.balanceOf(address(this)));
        }
    }

    function createVote(
        address defender_,
        uint dEthValue_,
        uint voterPercent_,
        uint freezeDuration_,
        uint minWstethA_,
        uint wstethA_
    )
        external
        payable
    {
        require(_isPausedAttack == 0, "paused");

        address attacker = msg.sender;
        // _weth.deposit{value: address(this).balance}();
        _prepareWsteth(minWstethA_, wstethA_);
        uint aEthValue = _geth.balanceOf(address(this));

        require(defender_ != address(_devTeam));
        require(dEthValue_ >= _minDefenderFund, "dEthValue_ too small");
        require(voterPercent_ <= _maxVoterPercent, "voterPercent_ too high");
        require(freezeDuration_ >= _minFreezeDuration && freezeDuration_ <= _maxFreezeDuration, "freezeDuration_ invalid");
        require(aEthValue <= dEthValue_ && aEthValue * LPercentage.DEMI / dEthValue_ >= _minAttackerFundRate, "aEthValue invalid");

        uint aQuorum = LHelper.calAQuorum(
            aEthValue,
            dEthValue_,
            voterPercent_,
            freezeDuration_,
            _freezeDurationUnit
        );

        _voting.clean();
        _eEarning.withdraw(defender_, dEthValue_, address(_voting));
        _geth.transfer(address(_voting), aEthValue);

        _dct.transferFrom(attacker, address(0xdead), _attackFee);

        _voting.createVote(
            attacker,
            defender_,
            aEthValue,
            dEthValue_,
            voterPercent_,
            aQuorum,
            block.timestamp,
            block.timestamp + freezeDuration_
        );

        _reCalFs(defender_);
    }

    function votingClaimFor(
        uint voteId_,
        address voter_
    )
        external
    {
        IVoting.SVoteBasicInfo memory vote = _voting.getVote(voteId_);
        bool isFinalizedBefore = vote.isFinalized;

        _voting.claimFor(voteId_, voter_);

        if (!isFinalizedBefore) {
            _reCalFs(vote.defender);
        }

        _reCalFs(voter_);
    }

    // DevTeam
    function earningWithdrawDevTeam()
        public
    {
        _eEarning.withdraw(address(_devTeam), _eEarning.earningOf(address(_devTeam)), address(_devTeam));
        _dEarning.withdraw(address(_devTeam), _dEarning.earningOf(address(_devTeam)), address(0xdead));

        _devTeam.distribute();
    }

    function claimRevenueShareDevTeam()
        public
    {
        address account = msg.sender;
        earningWithdrawDevTeam();
        _devTeam.claimFor(account, address(this));

        LLido.allToEth(0);
        payable(account).transfer(address(this).balance);
    }

    // ADMIN: CONFIGS
    function updateConfigs(
        uint[] memory values_
    )
        external
        onlyAdmin
    {

        require(values_[0] <= 300, "max 3%");
        _bountyPullEarningPercent = values_[0];

        _maxBooster = values_[1];

        _maxSponsorAdv = values_[2];
        _maxSponsorAfter = values_[3];

        _attackFee = values_[4];
        _maxVoterPercent = values_[5];
        _minAttackerFundRate = values_[6];
        _freezeDurationUnit = values_[7];
        _selfStakeAdvantage = values_[8];

        _profileC.setDefaultSPercentConfig(values_[9]);
        _isPausedAttack = values_[10];

        _profileC.setMinSPercentConfig(values_[11]);

        _dctTaxPercent = values_[12];

        _minFreezeDuration = values_[13];
        _maxFreezeDuration = values_[14];

        _minStakeETHAmount = values_[15];
        _minStakeDCTAmount = values_[16];

        _minDefenderFund = values_[17];

        emit AdminUpdateConfig(values_);
    }
}
