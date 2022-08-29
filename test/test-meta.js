/* eslint-disable */
const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {utils} = require("ethers");
const web3 = require("web3");
const {has} = require("lodash");

describe('MetaTx', () => {
    let deployer, consumer, forwarder, forwarderContract, nft, nftContract;

    beforeEach(async () => {
        [deployer, consumer] = await ethers.getSigners();

        forwarderContract = await ethers.getContractFactory("Proxy");
        forwarder = await forwarderContract.connect(deployer).deploy();

        nftContract = await ethers.getContractFactory("Coin");
        nft = await nftContract.connect(deployer).deploy();
    });


    it('should be possible to do a meta transaction', async () => {
        // const fnSignature =  utils.keccak256(utils.toUtf8Bytes("balanceOf(address)")).substr(0,10)

    const abiCoder = ethers.utils.defaultAbiCoder;

consumer = deployer

    const from = consumer.address
    const to = "0xDb63821949F870a36b321876AD9c69a482D582C5" 
    const tokenValue = "1"

    
         let fnParams = abiCoder.encode(
             ["address","address","uint256"],
             [from,to,tokenValue]
          )
        //   let fnParams = abiCoder.encode(
        //     ["address",],
        //     [consumer.address]
        //   )
          
          calldata = fnSignature + fnParams.substr(2)

        let nonce = await ethers.provider.getTransactionCount(from, "latest")


        let typed = [
            forwarder.address,
            calldata,
            consumer.address,
            nft.address,
            nonce,
            0
        ]

        let hashed = web3.utils.soliditySha3(...typed)


        let  signed = await consumer.signMessage(ethers.utils.arrayify(hashed));
        let split = ethers.utils.splitSignature(signed);


         const tokenCa = "0x793D5B39C44bAb587089b26fD2A02E87884bfA31";
         const ProxyCa = "0x39EaFdbDA1c6FaFD03657F4bac6f2EeEdf0c115f";


    const tokenC = await ethers.getContractFactory('Coin', deployer.address)
    .then(o => o.attach(tokenCa));
    const ProxyC = await ethers.getContractFactory('Proxy', deployer.address)
    .then(o => o.attach(ProxyCa));


  //  const fwdTx2 = await tokenC.approve(ProxyCa, "1111111111111111")
  //  const receipt2 = await fwdTx2.wait();
  //  console.log(receipt2)


  const fwdTx = await ProxyC.forward(tokenCa, calldata, hashed, split.v, split.r, split.s)
  const receipt = await fwdTx.wait();
  console.log(receipt)


    }).timeout(100000000000);
})