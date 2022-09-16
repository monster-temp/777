require('dotenv').config()

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import { ethers } from "hardhat";
import * as _ from 'lodash';
import "hardhat-contract-sizer";



task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('generate-pk', 'Generate private key', async (_, { ethers }) => {
  const signer = ethers.Wallet.createRandom();
  console.log(`Address: ${signer.address}`);
  console.log(`PK: ${signer.privateKey}`);
});

const accounts = [
  process.env.MINTER_PK           || '0x1111111111111111111111111111111111111111111111111111111111111110', // 0
  // process.env.OWNER_PK            || '0x1111111111111111111111111111111111111111111111111111111111111111', // 1
  //                                    '0x1111111111111111111111111111111111111111111111111111111111111112', // 2. approved (used in tests only)
  //                                    '0x1111111111111111111111111111111111111111111111111111111111111113', // 3. receiver (used in tests only)
  // process.env.BRIDGE_DEPLOYER_PK  || '0x1111111111111111111111111111111111111111111111111111111111111114', // 4
  // process.env.VALIDATOR_PK        || '0x1111111111111111111111111111111111111111111111111111111111111115', // 5
];

console.log(accounts);

if(accounts.length !== _.uniq(accounts).length) {
  console.error('Private keys not unique! Hardhat produce different addresses for same private keys');
}

import './tasks/deploy-token';
import './tasks/deploy-proxy';
import './tasks/test';





const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [{
      version: '0.8.16',
      settings: {
        optimizer: {
          enabled: true,
          runs: 999999,
        }
      }
    }],
  },
  networks: {
    hardhat: {
      chainId: 1337,
      blockGasLimit: 60_000_000, // BSC
      gasPrice: 5_000_000_000, // 5 Gwei
      accounts: accounts.map(privateKey => ({privateKey, balance: '10000000000000000000000'})),
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      chainId: 4,
      blockGasLimit: 6000000, // BSC
      gasPrice: 20000000000, // 10 Gwei
      accounts,
    },
    tbnb: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      chainId: 97,
      blockGasLimit: 60_000_000, // BSC
      gasPrice: 10_000_000_000, // 10 Gwei
      accounts,
    },
    tmatic: {
      url: process.env.TMATIC_RPC || 'https://rpc-mumbai.maticvigil.com/',
      chainId: 80001,
      accounts,
    },
    bnb: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      blockGasLimit: 60_000_000, // BSC
      gasPrice: 5_000_000_000, // 5 Gwei
      accounts,
    },
    matic: {
      url: 'https://rpc-mainnet.maticvigil.com/',
      chainId: 137,
      gasPrice: 50_000_000_000, // 50 Gwei
      accounts,
    },
  },
  etherscan: {
    //bsc MX67DUFWSSPC3HAWZ3TFFZT88SS6QGAIDQ
    apiKey: 'MX67DUFWSSPC3HAWZ3TFFZT88SS6QGAIDQ'
  }
};

export default config;
