# Anotherblock Platform Contracts

## Preliminary steps

Create `.env` file in the root directory as per `.env.example`

Source the `.env` file (from the root directory):

    source .env

## Compile Contracts

    forge build

## Test Contracts

To execute test cases, run :

    forge test --fork-url $OPTIMISM_RPC -vvv

To analyze test coverage, run :

    forge coverage --fork-url $OPTIMISM_RPC

### Deploy Contracts

Deploy and verify ABSuperToken (Superfluid mock token) :

    forge script script/01-deploy-ABSuperToken.s.sol:DeployMockSuperToken --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}

Deploy and verify AnotherCloneFactory (and related contracts) :

    forge script script/02-deploy-AnotherCloneFactory.s.sol:DeployAnotherCloneFactory --rpc-url optimism-goerli --broadcast --verify --etherscan-api-key ${OPTIMISM_ETHERSCAN_API_KEY}
