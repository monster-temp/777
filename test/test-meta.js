/* eslint-disable */
const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {utils} = require("ethers");
const web3 = require("web3");
const {has} = require("lodash");

describe('MetaTx', () => {

    beforeEach(async () => {

        forwarderContract = await ethers.getContractFactory("Proxy");
        forwarder = await forwarderContract.connect(deployer).deploy();

        nftContract = await ethers.getContractFactory("Coin");
        nft = await nftContract.connect(deployer).deploy();
    });


    it('should be possible to do a meta transaction', async () => {
        }).timeout(100000000000);
})