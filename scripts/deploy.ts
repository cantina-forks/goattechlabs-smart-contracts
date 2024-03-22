import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

const GETH = "0x1427bbe2429c6b15305243bf8dc12e4362d449fd";
const DEAD_ADDRESS = "0x000000000000000000000000000000000000dEaD";

const fromWei = (value: any) => {
  try {
    return ethers.utils.formatUnits(value.toString(), "ether");
  } catch (error: any) {
    console.log(error.mesasge);
    return "0";
  }
};

const toWei = (value: any) => {
  try {
    return ethers.utils.parseUnits(value.toString(), "ether");
  } catch (error: any) {
    console.log(error.mesasge);
    return "0";
  }
};

const waitMs = (msDuration: number) => {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve(null);
    }, msDuration);
  });
};

const SETTINGS = {};

var signer: any;

async function main() {
  if (!process.env.RPC_ENDPOINT || !process.env.PKEY) {
    throw "Missing PRC or PKey!";
  }

  const [owner] = await ethers.getSigners();
  signer = owner;

  console.log("xxx signer address", signer.address);

  //DEPLOY ONE TIME, TO GET ADDRESS WSTETH

  const balance = await ethers.provider.getBalance(signer.address);
  console.log({ balance });

  // const TESTNETINIT = await ethers.getContractFactory("TestnetInit");
  // await TESTNETINIT.deploy()
  // return;
  const LLido = await ethers.getContractFactory("LLido");
  const llido = await LLido.deploy();
  console.log("llido: ", llido.address);

  const Controller = await ethers.getContractFactory("Controller", {
    libraries: {
      LLido: llido.address,
    },
  });
  const controller = await Controller.deploy();

  const DCT = await ethers.getContractFactory("DCT");
  const dct = await DCT.deploy();

  console.log("dct", dct.address);

  const GlobalAccessControl = await ethers.getContractFactory(
    "GlobalAccessControl"
  );
  const globalAccessControl = await GlobalAccessControl.deploy();

  const ADMIN = "0x6d9cD20Ba0Dc1CCE0C645a6b5759f5ad1bD2704F";

  const PoolFactory = await ethers.getContractFactory("PoolFactory");
  const poolFactory = await PoolFactory.deploy();

  console.log("poolFactory", poolFactory.address);

  const Profile = await ethers.getContractFactory("Profile");
  const profile = await Profile.deploy();

  console.log("profile", profile.address);

  const Locker = await ethers.getContractFactory("Locker");
  const eLocker = await Locker.deploy();
  const dLocker = await Locker.deploy();

  console.log("eLocker", eLocker.address);
  console.log("dLocker", dLocker.address);

  const DToken = await ethers.getContractFactory("DToken");
  const eP2PDToken = await DToken.deploy();
  const dP2PDToken = await DToken.deploy();

  console.log("eP2PDToken", eP2PDToken.address);
  console.log("dP2PDToken", dP2PDToken.address);

  const Distributor = await ethers.getContractFactory("Distributor");
  // const eP2PDistributor = await Distributor.deploy();
  const dP2PDistributor = await Distributor.deploy();
  const eDP2PDistributor = await Distributor.deploy();
  const dDP2PDistributor = await Distributor.deploy();

  // console.log("eP2PDistributor", eP2PDistributor.address);
  console.log("dP2PDistributor", dP2PDistributor.address);
  console.log("eDP2PDistributor", eDP2PDistributor.address);
  console.log("dDP2PDistributor", dDP2PDistributor.address);

  const devTeamDToken = await DToken.deploy();
  const devTeamDistributor = await Distributor.deploy();

  const Earning = await ethers.getContractFactory("Earning");
  const eEarning = await Earning.deploy();
  const dEarning = await Earning.deploy();

  console.log("eEarning", eEarning.address);
  console.log("dEarning", dEarning.address);

  const Voting = await ethers.getContractFactory("Voting", {
    libraries: {
      LLido: llido.address,
    },
  });
  const voting = await Voting.deploy();

  console.log("voting", voting.address);

  const PrivateVester = await ethers.getContractFactory("PrivateVester");
  const privateVester = await PrivateVester.deploy();
  await dct.initDCT(
    globalAccessControl.address,
    dP2PDistributor.address,
    ADMIN,
    parseEther("2046666660"),
    DEAD_ADDRESS
  );

  console.log("initDCT");
  await waitMs(5000);
  const dctVester = await dct.vester();
  console.log("dctVester", dctVester);

  const EthSharing = await ethers.getContractFactory("EthSharing");
  const ethSharing = await EthSharing.deploy();

  const CONTRACT_ADDRESSES_MAP = {
    POOL_FACTORY: poolFactory.address.toLowerCase(),
    CONTROLLER: controller.address.toLowerCase(),
    PROFILE: profile.address.toLowerCase(),
    DCT_EARNING: dEarning.address.toLowerCase(),
    ETH_EARNING: eEarning.address.toLowerCase(),
    ETH_LOCKER: eLocker.address.toLowerCase(),
    DCT_LOCKER: dLocker.address.toLowerCase(),
    E_P2P_DTOKEN: eP2PDToken.address.toLowerCase(),
    D_P2P_DTOKEN: dP2PDToken.address.toLowerCase(),
    DCT: dct.address.toLowerCase(),
    VOTING: voting.address.toLowerCase(),
    E_DP2P_DISTRIBUTOR: eDP2PDistributor.address.toLowerCase(),
    D_DP2P_DISTRIBUTOR: dDP2PDistributor.address.toLowerCase(),
    MULTICALL: "0xea4172c0033e6e90db9d2ee6e56cd27889ff09c3",
    // eP2PDistributor: eP2PDistributor.address.toLowerCase(),
    D_P2P_DISTRIBUTOR: dP2PDistributor.address.toLowerCase(),
    GLOBAL_ACCESS: globalAccessControl.address.toLowerCase(),
    DEV_TEAM_DTOKEN: devTeamDToken.address.toLowerCase(),
    DEV_TEAM_DISTRIBUTOR: devTeamDistributor.address.toLowerCase(),
    PRIVATE_VESTER: privateVester.address.toLowerCase(),
    DCT_VESTER: dctVester.toLowerCase(),
    ETH_SHARING: ethSharing.address.toLowerCase(),
    llido: llido.address.toLowerCase(),
  };

  var fs = require("fs");
  fs.writeFileSync(
    "contracts.json",
    JSON.stringify(CONTRACT_ADDRESSES_MAP, null, 4)
  );

  await privateVester.config(dctVester, dct.address);
  console.log("config privateVester");

  await globalAccessControl.addAdmins([
    controller.address,
    privateVester.address,
    ADMIN,
  ]);

  console.log("addAdmins");

  // await eP2PDistributor.initDistributor(
  //   globalAccessControl.address,
  //   eP2PDToken.address,
  //   geth.address
  // );

  // console.log("init eP2PDistributor");

  await ethSharing.initEthSharing(globalAccessControl.address, 100, 200, 300);

  console.log("init ethSharing");

  await dP2PDistributor.initDistributor(
    globalAccessControl.address,
    eP2PDToken.address,
    dct.address
  );

  console.log("init dP2PDistributor");

  await eP2PDToken.initDToken(
    globalAccessControl.address,
    true,
    "eP2PDToken",
    "eP2PDToken",
    [dP2PDistributor.address]
    // [dP2PDistributor.address, eP2PDistributor.address]
  );

  console.log("init eP2PDToken");

  await eDP2PDistributor.initDistributor(
    globalAccessControl.address,
    dP2PDToken.address,
    GETH
  );
  console.log("init eDP2PDistributor");

  await dDP2PDistributor.initDistributor(
    globalAccessControl.address,
    dP2PDToken.address,
    dct.address
  );
  console.log("init dDP2PDistributor");

  await dP2PDToken.initDToken(
    globalAccessControl.address,
    true,
    "dP2PDToken",
    "dP2PDToken",
    [eDP2PDistributor.address, dDP2PDistributor.address]
  );

  console.log("init dP2PDToken");

  await poolFactory.initPoolFactory(
    globalAccessControl.address,
    GETH,
    dct.address
  );

  console.log("init poolFactory");

  await profile.initProfile(globalAccessControl.address);

  console.log("init profile");

  await eLocker.initLocker(
    globalAccessControl.address,
    GETH,
    profile.address,
    eDP2PDistributor.address,
    eDP2PDistributor.address
  );

  console.log("init eLocker");

  await dLocker.initLocker(
    globalAccessControl.address,
    dct.address,
    profile.address,
    DEAD_ADDRESS,
    DEAD_ADDRESS
  );

  console.log("init dLocker");

  await eEarning.initEarning(
    GETH,
    profile.address,
    globalAccessControl.address,
    "ETH Earning",
    "ETHE",
    eDP2PDistributor.address
  );

  console.log("init eEarning");

  await dEarning.initEarning(
    dct.address,
    profile.address,
    globalAccessControl.address,
    "DCT Earning",
    "DCTE",
    DEAD_ADDRESS
  );

  console.log("init dEarning");

  await voting.initVoting(
    globalAccessControl.address,
    dP2PDToken.address,
    GETH,
    eEarning.address,
    eDP2PDistributor.address
  );

  console.log("init voting");

  await controller.initController([
    GETH,
    dct.address,

    globalAccessControl.address,
    devTeamDistributor.address,
    poolFactory.address,
    profile.address,

    eLocker.address,
    eP2PDToken.address,
    // eP2PDistributor.address,
    eEarning.address,

    dLocker.address,
    dP2PDToken.address,
    dP2PDistributor.address,
    dEarning.address,

    voting.address,

    eDP2PDistributor.address,
    dDP2PDistributor.address,

    ethSharing.address,
  ]);
  console.log("initController");

  // DEV TEAM init
  await devTeamDToken.initDToken(
    globalAccessControl.address,
    true,
    "devTeamDToken",
    "devTeamDToken",
    [devTeamDistributor.address]
  );
  console.log("init devTeamDToken");

  await devTeamDistributor.initDistributor(
    globalAccessControl.address,
    devTeamDToken.address,
    GETH
  );
  console.log("init devTeamDistributor");
  //=========

  const contracts = [
    {
      name: "Controller",
      address: controller.address,
    },

    {
      name: "GETH",
      address: GETH,
    },
    {
      name: "DCT",
      address: dct.address,
    },

    {
      name: "GlobalAccessControl",
      address: globalAccessControl.address,
    },
    {
      name: "devTeamDistributor",
      address: devTeamDistributor.address,
    },
    {
      name: "devTeamDToken",
      address: devTeamDToken.address,
    },
    {
      name: "PoolFactory",
      address: poolFactory.address,
    },
    {
      name: "Profile",
      address: profile.address,
    },

    {
      name: "eLocker",
      address: eLocker.address,
    },
    {
      name: "eP2PDToken",
      address: eP2PDToken.address,
    },
    // {
    //   name: "eP2PDistributor",
    //   address: eP2PDistributor.address,
    // },
    {
      name: "eEarning",
      address: eEarning.address,
    },

    {
      name: "dLocker",
      address: dLocker.address,
    },
    {
      name: "dP2PDToken",
      address: dP2PDToken.address,
    },
    {
      name: "dP2PDistributor",
      address: dP2PDistributor.address,
    },
    {
      name: "dEarning",
      address: dEarning.address,
    },
    {
      name: "eDP2PDistributor",
      address: eDP2PDistributor.address,
    },
    {
      name: "dDP2PDistributor",
      address: dDP2PDistributor.address,
    },
    {
      name: "Voting",
      address: voting.address,
    },
    {
      name: "PrivateVester",
      address: privateVester.address,
    },
    {
      name: "dctVester",
      address: dctVester,
    },
    {
      name: "ethSharing",
      address: ethSharing.address,
    },
    {
      name: "llido",
      address: llido.address,
    },
  ];
  console.log(contracts);

  // const toWei = (value: any) => {
  //   return ethers.utils.parseEther(value.toString());
  // };

  // const fromWei = (value: any) => {
  //   return ethers.utils.formatEther(value.toString());
  // };

  // const account = signer.address;
  // const duration = 3 * 60;
  // const isPoolCreated = false;
  // const minSPercent = 0;
  // const value = 100;
  // await controller.ethStake(account, duration, isPoolCreated, minSPercent, {
  //   value: toWei(value),
  // });

  // console.log(account, "controller.ethStake", value);

  // await controller.earningPulls(account, [account]);

  // console.log(account, "controller.earningPulls");

  // await controller.ethStake(account, duration, true, minSPercent, {
  //   value: toWei(value),
  // });

  // console.log(account, "controller.ethStake", value);

  // await controller.earningPulls(account, [account]);

  // console.log(account, "controller.earningPulls");

  // const earningBalance = {
  //   eth: fromWei(await eEarning.balanceOf(account)),
  //   dct: fromWei(await dEarning.balanceOf(account)),
  // };

  // console.log(earningBalance);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
