# Anotherblock Platform Contracts

## Preliminary steps

Create `.env` file in the root directory as per `.env.example`

```sh
cp .env.example .env
```

Source the `.env` file (from the root directory):

    source .env

### Install foundry

https://book.getfoundry.sh/getting-started/installation

## Compile Contracts

    forge build

## Test Contracts

To execute test cases, run :

    forge test -vvv

To analyze test coverage, run :

    forge coverage

### Deploy Contracts

#### On Optimism Goerli :

Deploy and verify ABSuperToken (Superfluid mock token) :

    forge script script/01-deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}

Simulate Deployment :

    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli

Deploy and verify AnotherCloneFactory (and related contracts) :

    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}

#### On Base Goerli :

Deploy and verify ABSuperToken (Superfluid mock token) :

    forge script script/base/deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url base-goerli --broadcast --verify

Simulate Deployment :

    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli

Deploy and verify AnotherCloneFactory (and related contracts) :

    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli --broadcast --verify
