Build Goat.Tech with Solidity 0.8.8

There are 8 contract files in the "Contracts" folder
https://github.com/goattechlabs/Smart-contracts/tree/main/contracts
- Controller.sol (important): contains most of the core logic; allows admin to set/modify protocol parameters; is approved by users to withdraw unlocked funds from Locker contracts.
- DCT.sol: the $GOAT token contract.
- GlobalAccessControl.sol: when called by an address, other contracts will call this contract to check whether the calling address has access (is admin) or not.
- PoolFactory.sol: creates a "Trust Pool" for each user, so that other users can stake ETH in that pool.
- PrivateVester.sol: allows setting/modifying vesting schedule for $GOAT token.
- Profile.sol: stores on-chain information and parameters of users.
- Voting.sol: allows users to create reputation Challenges and allows them to Vote on these Challenges; much like voting on proposals.
- EthSharing.sol: allow users to edit their pool's configuration, such as pool reward rate and staker reward rate.

There are 10 contract files in the "Modules" folder, which are repeatedly used code (to prevent code duplication)
https://github.com/goattechlabs/Smart-contracts/tree/main/contracts/modules
- AccessControl.sol: a module used by GlobalAccessControl.sol.
- Cashier.sol (important): facilitates users' depositing & withdrawing funds to/from other contracts.
- DToken.sol: dividend token that stands for a share in reward distribution.
- Distribution.sol (important): distributes rewards to dividend token holders.
- Earning.sol: stores user earning and calculates different kinds of earnings.
- Initializable.sol
- Locker.sol (important): stores locked ETH and $GOAT; only Controller contract is approved (once by each user) to with unlocked funds from Locker contracts.
- PERC20.sol: private, non-transferrable ERC20.
- UserAccessControl.sol
- Vester.sol: stores and unlocks token according to vesting schedule set by PrivateVester contract.

In order to deploy all contracts —> please use scripts prepared here:
https://github.com/goattechlabs/Smart-contracts/tree/main/scripts

Walkthrough recording: (password = spearbit)
https://www.loom.com/share/ac84b075d0704532bd9922d611663c81

Walkthrough TRANSCRIPT:
https://github.com/goattechlabs/Smart-contracts/blob/main/RecordingTranscript.md

=======

From 18 contract files above, 21 contracts have been successfully deployed on Sepolia Arbitrum testnet. The Dapp is live on https://Arb.Goat.Tech
Some of these contracts use the same code, for example DCT_earning and ETH_earning use earning.sol, the xxx_dtoken contracts use dtoken.sol, and the xxx_distributor contracts use distributor.sol.

    POOL_FACTORY: '0x8e0caee3d94d5497744e2db30eec2d222739df6d': When a pool is created, a P2U_dtoken for that pool will also be deployed; when a user stake in this pool, it will receive this P2U dtoken which represents its Staking Power in this pool (its share of all rewards received through this pool).
    CONTROLLER: '0xb4e5f0b2885f09fd5a078d86e94e5d2e4b8530a7'
    PROFILE: '0x7c25c3edd4576b78b4f8aa1128320ae3d7204bec'
    DCT_EARNING: '0xecc07bf95d53268d9204ec58788c4df067ce075c': stores and calculate user earning in $GOAT.
    ETH_EARNING: '0xf7a08a0728c583075852be8b67e47dceb5c71d48': stores and calculate user earning in ETH.
    ETH_LOCKER: '0x0265850fe8a0615260a1008e1c1df01db394e74a': stores locked ETH.
    DCT_LOCKER: '0x1033d5f886aef22ffadebf5f8c34088030bb80f3': stores locked $GOAT.
    E_P2P_DTOKEN: '0x8b64439a617bb1e85f83b97ea779edef49b9dcb2': a pool owner earns Ep2p dtoken when ETH is staked in its pool; this dtoken balance is called the Trust Score.
    D_P2P_DTOKEN: '0x72835409b8b49d83d8a710e67c906ae313d22860': a user earns Dp2p dtoken when staking $GOAT in its own pool; this dtoken balance is called Boost-Vote Power (because it's used to Boost one's Trust Score, and Vote on Challenges); this dtoken represents all $GOAT stakers.
    DCT: '0x5bfe38c9f309aed44daa035abf69c80786355136': $GOAT token.
    VOTING: '0x896604b21c6e9cbce82e096266dcb5798cdda67b'
    E_DP2P_DISTRIBUTOR: '0x6df03a30c6f428b88c2bc9cb150d752935d971d0': airdrop/distribute ETH rewards to all Dp2p dtoken holders ($GOAT stakers) pro-rata.
    D_DP2P_DISTRIBUTOR: '0xb087427ba44ed71a40ac80b86e41420b7fb595ec': airdrop/distribute $GOAT rewards to all Dp2p dtoken holders ($GOAT stakers) pro-rata.
    MULTICALL: '0xea4172c0033e6e90db9d2ee6e56cd27889ff09c3'
    D_P2P_DISTRIBUTOR: '0x88185cd296fd85169ee6152728daaef5fcca9c0a': distribute $GOAT (Mining Reward) in 2 steps - to all pools based pool owners' Trust Score (Ep2p dtoken balance) pro-rata, and then to all stakers in each pool based on each staker's Staking Power (P2U dtoken) in that particular pool pro-rata.
    GLOBAL_ACCESS: '0x588cf1494c5ac93796134e5e1827f58d2a8a9cdb'
    DEV_TEAM_DTOKEN: '0x03340c677ae7d887e8c4bd57e2fac10c75c479df': dtoken for Protocol Revenue.
    DEV_TEAM_DISTRIBUTOR: '0xa42901fc3a89cd2f3ac97b43cf5069b4ef51f40a': distribute ETH Protocol Revenue pro-rata.
    PRIVATE_VESTER: '0x484a42a88eb7f673ec3f688ebb17bfa2341ab562'
    DCT_VESTER: '0xcbc65770b01bf12f7ccf8ce25adce9c807510976'
    ETH_SHARING: '0xe8330ece50934eac7457a712f9079d7775b04c9a'

=======

How to feed Goat.Tech Trust Score On-Chain:

Step 1: retrieve the pool address of a user address by calling the getPool(address) function of contract PoolFactory, which is 0x854626ec1e654ecdce94b39e5896587881f844d4 (on Blast Sepolia).

     const pool = await ContractPoolFactory.methods.getPool("0x1c60244959213ba28610dd0702bb50cc98328e75").call()
     const dctDistributor = pool.dctDistributor;

Step 2: Call balanceOf(pool.dctDistributor) function of contract EP2PDToken, which is 0xda73d0e531fce6ddb355ba7d324e7955ebbe15f0 (on Blast Sepolia).

    const trustScore = await ContractEP2PDToken.methods.balanceOf(dctDistributor).call()

ABI Interface of contract PoolFactory: PoolFactoryABI.json
ABI Interface of contract EP2PDToken: EP2PDTokenABI.json

END.
