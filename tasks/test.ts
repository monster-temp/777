// import { task } from "hardhat/config";
// import { getNamedAccounts } from "../utils/named-accounts";
// const abi = require('./routerabi.json')
// const lpabi = require('./lpabi.json')
// import { toWei, fromWei } from "web3-utils";
// const tokenabi = require('../artifacts/contracts/777.sol/Jackpot.json').abi

// task('test', 'testt')
//   .setAction(async (args: {}, { ethers }) => {
//     const { minter } = await getNamedAccounts(ethers);

//     const router = '0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3'
//     const pair = '0x02eF9E389b6B2Ff5720e522b8649634b32F55d29'
//     const wbnb = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd'
//     const token = '0xc0425198f466781bc9a308fccbd6fcbd77f4a615'

//     const erc20 = new ethers.Contract(
//         router,
//         abi,
//         minter
//     );
//     const paircontract = new ethers.Contract(
//         pair,
//         lpabi,
//         minter
//     );
//     const tokencontract = new ethers.Contract(
//         token,
//         tokenabi,
//         minter
//     )
//     // const test2 = await paircontract.getReserves()
//     // const _reserveTOken = test2._reserve0.toString()
//     // const reserveTOken = _reserveTOken/ (10**18)
//     // const _reserveBNB = test2._reserve1.toString()
//     // const reserveBNB = _reserveBNB/ (10**18)
//  //   const reserveToken = ethers.utils.formatEther(reserveTOken)
//     // const prod = reserveTOken * reserveBNB
//     // console.log('prod', prod)
//     // const newReserve = prod / (reserveTOken * 10)
//     // console.log('newReserve', newReserve)

//     // const calc = reserveBNB - newReserve
//     // console.log('calc', calc)

//     // const getTokenExchangeRate = async (tokenA:any, tokenB:any) => {
//     //     return (
//     //       await erc20.getAmountsOut(toWei("1"), [tokenA, tokenB])
//     //     )[1];
//     //   };
//     //   const _price = await getTokenExchangeRate(token,wbnb)
//     //   const price = _price / (10 ** 18)
//     //   console.log('price', price)
//     //   console.log('wei', toWei("1"))
// //    const input_token_amount = calc * (10 ** 18) 
// //    const amounts_out = erc20.getAmountsOut(input_token_amount, [self.w3.toChecksumAddress(input_token.token_address), self.w3.toChecksumAddress(output_token.token_address)]).call()
// //    const amount_out = amounts_out[1] / (10 ** output_token.token_decimals) 
//    // const test =await erc20.getAmountsOut(1, [ token, wbnb])
// //    const inactive = await tokencontract.setLotteryInactiveDaily().then((res:any) => {
// //     console.log('res', res) })

// //     console.log(inactive)
//  const draw = await tokencontract.triggerLotteryDrawingDaily().then((res:any) => {
//     console.log('res', res) })

//     console.log(draw)

  
// });
