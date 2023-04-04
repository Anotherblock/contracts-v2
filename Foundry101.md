# Foundry 101

## Foundry Advantages

1. Fast
2. Built-in fuzzing
3. Solidity based testing
4. EVM Cheat codes
5. Script based in shell / bash

## Resources

### Repo

- https://github.com/PatrickAlphaC/foundry-play
- https://github.com/smartcontractkit/foundry-starter-kit

### Docs

- https://book.getfoundry.sh/

## Installation

Run :

    curl -L https://foundry.paradigm.xyz | bash

Then :

    foundryup

## Workflow

### Initialize Repository

    forge init --force

### Compile Contracts

    forge build

### Install Solidity Dependencies

First, install the dependency :

    forge install GithubOrg/GithubRepo

Then, add the dependency to `foundry.toml` in the remappings tag

For example, to install Openzepplin contracts repository :

CLI :

    forge install OpenZeppelin/openzeppelin-contracts

foundry.toml :

    remappings = ['@openzeppelin/=lib/openzeppelin-contracts/']

### Test Contracts

To execute test cases, run :

    forge test --fork-url <RPC_URL> -vvv

To analyze test coverage, run :

    forge coverage --fork-url <RPC_URL>

### Deploy Contracts

Using CLI directly :

    forge create --rpc-url <your_rpc_url> --private-key <your_private_key> src/MyContract.sol:MyContract

Using Forge Scripts :

    forge script script/Contract.s.sol:Contract --rpc-url $OPTIMISM_GOERLI_RPC --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}

### Run local node

To start a local testnet to test against, run :

    anvil

See anvil configuration :

    anvil -h
