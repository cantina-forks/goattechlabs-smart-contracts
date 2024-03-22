Build Decentrust with Solidity 0.8.8

21 contracts have been successfully deployed on Sepolia Arbitrum testnet. 
The Dapp is live on https://Arb.Goat.Tech
Some of these contracts use the same code, for example DCT_earning and ETH_earning use earning.sol, the xxx_dtoken contracts use dtoken.sol, and the xxx_distributor contracts use distributor.sol.

    POOL_FACTORY: '0x8e0caee3d94d5497744e2db30eec2d222739df6d'
    CONTROLLER: '0xb4e5f0b2885f09fd5a078d86e94e5d2e4b8530a7'
    PROFILE: '0x7c25c3edd4576b78b4f8aa1128320ae3d7204bec'
    DCT_EARNING: '0xecc07bf95d53268d9204ec58788c4df067ce075c'
    ETH_EARNING: '0xf7a08a0728c583075852be8b67e47dceb5c71d48'
    ETH_LOCKER: '0x0265850fe8a0615260a1008e1c1df01db394e74a'
    DCT_LOCKER: '0x1033d5f886aef22ffadebf5f8c34088030bb80f3'
    E_P2P_DTOKEN: '0x8b64439a617bb1e85f83b97ea779edef49b9dcb2'
    D_P2P_DTOKEN: '0x72835409b8b49d83d8a710e67c906ae313d22860'
    DCT: '0x5bfe38c9f309aed44daa035abf69c80786355136'
    VOTING: '0x896604b21c6e9cbce82e096266dcb5798cdda67b'
    E_DP2P_DISTRIBUTOR: '0x6df03a30c6f428b88c2bc9cb150d752935d971d0'
    D_DP2P_DISTRIBUTOR: '0xb087427ba44ed71a40ac80b86e41420b7fb595ec'
    MULTICALL: '0xea4172c0033e6e90db9d2ee6e56cd27889ff09c3'
    D_P2P_DISTRIBUTOR: '0x88185cd296fd85169ee6152728daaef5fcca9c0a'
    GLOBAL_ACCESS: '0x588cf1494c5ac93796134e5e1827f58d2a8a9cdb'
    DEV_TEAM_DTOKEN: '0x03340c677ae7d887e8c4bd57e2fac10c75c479df'
    DEV_TEAM_DISTRIBUTOR: '0xa42901fc3a89cd2f3ac97b43cf5069b4ef51f40a'
    PRIVATE_VESTER: '0x484a42a88eb7f673ec3f688ebb17bfa2341ab562'
    DCT_VESTER: '0xcbc65770b01bf12f7ccf8ce25adce9c807510976'
    ETH_SHARING: '0xe8330ece50934eac7457a712f9079d7775b04c9a'

There are 7 contract files in the "Contracts" folder 
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
- Cashier.sol: facilitates users' depositing & withdrawing funds to/from other contracts.
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
