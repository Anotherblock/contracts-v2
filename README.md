# Anotherblock Platform Contracts

## Install foundry

[Foundry Installation procedure](https://book.getfoundry.sh/getting-started/installation)

## Setup environment

Create `.env` file in the root directory as per `.env.example`

```sh
cp .env.example .env
```

Source the `.env` file (from the root directory):

```sh
source .env
```

## Compile Contracts

```sh
forge build
```

## Test Contracts

Execute full test campaign :

```sh
forge test -vvv
```

Analyze test coverage :

```sh
forge coverage
```

## Deploy Contracts

### Optimism Goerli :

Deploy and verify ABSuperToken (Superfluid mock token) :

```sh
forge script script/op/deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}
```

Simulate Deployment :

```sh
    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli
```

Deploy and verify anotherblock platform contracts :

```sh
    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}
```

### Base Goerli :

Simulate Deployment :

```sh
    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli
```

Deploy and verify anotherblock platform contracts :

```sh
    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli --broadcast --verify
```
