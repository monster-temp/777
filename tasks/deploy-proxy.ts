// import { task } from "hardhat/config";
// import { getNamedAccounts } from "../utils/named-accounts";

// task('deploy-proxy', 'Deploy Proxy contract')
 
//   .setAction(async (args: { }, { ethers }) => {
//     const { bridgeDeployer, validatorSigner } = await getNamedAccounts(ethers);
//     const Proxy = await ethers.getContractFactory('Proxy', bridgeDeployer);

//     const proxy = await Proxy.deploy();
//     await proxy.deployed();

//     console.log('Proxy Contract deployed to address:', proxy.address); //0x2e4f4191758c43f51dc7761620495E2E8839b2f4
//   });
