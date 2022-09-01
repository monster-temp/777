# 777 Jackpot Token

## Developing

* `yarn`
* configure `.env` based on `.env.example`
* `yarn hardhat node` # private network
* `yarn build` # build contracts


## Task usage examples
* `yarn hardhat deploy-token --network DESIRED_NETWORK` (deploy token)
* `yarn hardhat verify --network DESIRED_NETWORK CONTRACT_ADDRESS` (verify token)
* `yarn hardhat test --network DESIRED_NETWORK` (update networks hardhat.config.ts according to desired networks)
