import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";

import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";

dotenv.config();

const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
const GOERLI_ALCHEMY_KEY = process.env.GOERLI_ALCHEMY_KEY;
const OPTIMISM_GOERLI_ALCHEMY_KEY = process.env.OPTIMISM_GOERLI_ALCHEMY_KEY;
const OPTIMISM_ALCHEMY_KEY = process.env.OPTIMISM_MAINNET_ALCHEMY_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10,
      },
    },
  },
  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
      mining: {
        auto: true,
        interval: 5000,
      },
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    optimism: {
      chainId: 10,
      url: `https://opt-mainnet.g.alchemy.com/v2/${OPTIMISM_ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${GOERLI_ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    optimismGoerli: {
      chainId: 420,
      url: `https://opt-goerli.g.alchemy.com/v2/${OPTIMISM_GOERLI_ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    baseGoerli: {
      url: "https://1rpc.io/base-goerli",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources: "./src",
    tests: "./test",
    artifacts: "./artifacts",
  },

  etherscan: {
    apiKey: {
      mainnet: `${process.env.ETHERSCAN_API_KEY}`,
      optimism: `${process.env.OPTIMISM_ETHERSCAN_API_KEY}`,
      goerli: `${process.env.ETHERSCAN_API_KEY}`,
      optimismGoerli: `${process.env.OPTIMISM_ETHERSCAN_API_KEY}`,
    },
    customChains: [
      {
        network: "optimismGoerli",
        chainId: 420,
        urls: {
          apiURL: "https://api-goerli-optimism.etherscan.io/api",
          browserURL: "https://goerli-optimism.etherscan.io/",
        },
      },
      {
        network: "optimism",
        chainId: 10,
        urls: {
          apiURL: "https://api-optimistic.etherscan.io/api",
          browserURL: "https://optimistic.etherscan.io/",
        },
      },
    ],
  },
};

export default config;
