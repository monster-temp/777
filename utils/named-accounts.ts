import type { ethers as Ethers } from 'ethers';

import { HardhatEthersHelpers } from '@nomiclabs/hardhat-ethers/types';


export async function getNamedAccounts(ethers: typeof Ethers & HardhatEthersHelpers) {
  const signers = await ethers.getSigners();
//console.log(signers)
  return {
    minter: signers[0],
    // owner: signers[0],
    // approved: signers[0],
    // receiver: signers[0],
    // bridgeDeployer: signers[0],
    // /*owner: signers[1],
    // approved: signers[2],
    // receiver: signers[3],
    // bridgeDeployer: signers[4], */

    // cannot signMessage by SignerWithAddress
   // validatorSigner: new ethers.Wallet(process.env.VALIDATOR_PK!),
  };
}
