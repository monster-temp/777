import { task } from "hardhat/config";
import { getNamedAccounts } from "../utils/named-accounts";

task('deploy-token', 'Deploy Token contract')
  .setAction(async (args: {}, { ethers }) => {
    const { minter } = await getNamedAccounts(ethers);
    const Token = await ethers.getContractFactory('Jackpot', minter);

   const token = await Token.deploy();
    await token.deployed();

   console.log('Token Contract deployed to address:', token.address);
  
});
