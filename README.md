# <img src="ab-logo.png" alt="anotherblock" height="40px" align="left"> anotherblock platform contracts

## contribution workflow

### branches

this git repository is composed of two main branches and feature branches :

#### latest

`latest` branch is synchronized with the latest contracts deployed on _mainnet_.
_after every mainnet deployment and/or upgrade_, a pull request from `dev` to `latest` must be initiated and merged.
this branch is the reference for any integration with other sub-systems, i.e. frontend, subgraphs, and so on.

#### dev

`dev` branch is accumulating and consolidating all the new features, bug fixes and upgrades that are _not yet deployed on mainnet_.
_mainnet deployment must be initiated_ from `dev` branch only after the end-to-end tests have been successfully conducted on testnet.
_testnet deployment must be initiated_ from `dev` branch.

#### feature branches

feature branches are created every time a new feature, bug fix or upgrade must be developped.
feature branches are created from `dev` branch.
feature branches naming convention is `abXXX-featName` where XXX is the Linear Ticket ID and featName is a brief feature description.
a feature branch can be merge to `dev` _only if all required units tests have been conducted and passed_ and after approval from relevant stakeholders that the feature, bug fix or upgrade will be fit for deployement on mainnet.

### tags

_after every mainnet deployment and/or upgrade_, a tag must be created
tag naming convention is `vX.Y` where X & Y are digits.
we increment `X` for major update while we increment `Y` for small update or patches.

## install foundry

[foundry installation procedure](https://book.getfoundry.sh/getting-started/installation)

## setup environment

create `.env` file in the root directory as per `.env.example`

```sh
cp .env.example .env
```

source the `.env` file (from the root directory):

```sh
source .env
```

## compile contracts

```sh
forge build
```

## test contracts

execute full test campaign :

```sh
forge test -vvv
```

analyze test coverage :

```sh
forge coverage
```

## deploy contracts

### optimism goerli :

deploy and verify ABSuperToken (superfluid mock token) :

```sh
forge script script/op/deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}
```

simulate platform deployment :

```sh
    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli --sig "run(bool)" true
```

deploy and verify anotherblock platform contracts :

```sh
    forge script script/op/deploy-platform.s.sol:DeployPlatform --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY} --sig "run(bool)" false
```

simulate ABRoyalty deployment

```sh
    forge script script/op/deploy-royalty.s.sol:DeployRoyalty --rpc-url base-goerli --sig "run(address)" <publisherAddress>
```

deploy standalone royalty contract for specific publisher

```sh
    forge script script/op/deploy-royalty.s.sol:DeployRoyalty --rpc-url base-goerli --sig "run(address)" <publisherAddress> --broadcast --verify
```

### base goerli :

deploy and verify ABSuperToken (superfluid mock token) :

```sh
forge script script/base-goerli/deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url base-goerli --broadcast --verify
```

simulate platform deployment :

```sh
    forge script script/base-goerli/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli --sig "run(bool)" true
```

deploy and verify anotherblock platform contracts :

```sh
    forge script script/base-goerli/deploy-platform.s.sol:DeployPlatform --rpc-url base-goerli --broadcast --verify --sig "run(bool)" false
```

simulate ABRoyalty deployment

```sh
    forge script script/base-goerli/deploy-royalty.s.sol:DeployRoyalty --rpc-url base-goerli --sig "run(address)" <publisherAddress>
```

deploy standalone royalty contract for specific publisher

```sh
    forge script script/base-goerli/deploy-royalty.s.sol:DeployRoyalty --rpc-url base-goerli --sig "run(address)" <publisherAddress> --broadcast --verify
```

### base mainnet :

simulate platform deployment :

```sh
    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base --sig "run(bool)" true
```

deploy and verify anotherblock platform contracts :

```sh
    forge script script/base/deploy-platform.s.sol:DeployPlatform --rpc-url base --broadcast --verify --sig "run(bool)" false
```

simulate ABRoyalty deployment

```sh
    forge script script/base/deploy-royalty.s.sol:DeployRoyalty --rpc-url base --sig "run(address)" <publisherAddress>
```

deploy standalone royalty contract for specific publisher

```sh
    forge script script/base/deploy-royalty.s.sol:DeployRoyalty --rpc-url base --sig "run(address)" <publisherAddress> --broadcast --verify
```

## contribute

### creating new NFT minting mechanism

in order for anyone to create new minting mechanism NFT contract compatible with anotherblock self-service platform, the contract must comply with below requirements :

1. the new contract shall inherit the abstract contract [ERC721AB](src/token/ERC721/ERC721AB.sol)

2. the new contract state shall include two constants, `IMPLEMENTATION_VERSION` & `IMPLEMENTATION_TYPE`

3. the new contract shall include a function `initDrop` calling the internal function `_initDrop` and contain a minimum set of parameters :

   - amount of share per token
   - amount of genesis token to be minted
   - recipient address of the genesis token(s)
   - currency used to pay-out royalties
   - base URI

4. the new contract shall include a custom mint function (see [ERC721ABLE](src/token//ERC721/ERC721ABLE.sol) for reference)
