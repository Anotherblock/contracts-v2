import { ethers } from "hardhat";

async function main() {
  const ERC721ABBASE_CONTRACT = await ethers.getContractFactory("ERC721ABBase");
  const ERC1155AB_CONTRACT = await ethers.getContractFactory("ERC1155AB");
  const AB_ROYALTY_CONTRACT = await ethers.getContractFactory("ABRoyalty");
  const AB_VERIFIER_CONTRACT = await ethers.getContractFactory("ABVerifier");
  const AB_DATA_REGISTRY_CONTRACT = await ethers.getContractFactory(
    "ABDataRegistry"
  );

  const DROP_ID_OFFSET = 20_000;
  const AB_TREASURY_ADDR = "0xd71256ec24925873ce9e9f085f89864ca05970bd";
  const ALLOWLIST_SIGNER = "0xd71256ec24925873ce9e9f085f89864ca05970bd";

  const AB_VERIFIER_ARGS = [ALLOWLIST_SIGNER];
  const AB_DATA_REGISTRY_ARGS = [DROP_ID_OFFSET, AB_TREASURY_ADDR];

  const erc721abBase = await ERC721ABBASE_CONTRACT.deploy();
  await erc721abBase.deployed();

  const erc1155ab = await ERC1155AB_CONTRACT.deploy();
  await erc1155ab.deployed();

  const abRoyalty = await AB_ROYALTY_CONTRACT.deploy();
  await abRoyalty.deployed();

  const abVerifier = await AB_VERIFIER_CONTRACT.deploy(ALLOWLIST_SIGNER);
  await abVerifier.deployed();

  const abDataRegistry = await AB_DATA_REGISTRY_CONTRACT.deploy(
    DROP_ID_OFFSET,
    AB_TREASURY_ADDR
  );
  await abDataRegistry.deployed();

  console.log("ERC721ABBase deployed to:", erc721abBase.address);
  console.log(
    `npx hardhat verify ${erc721abBase.address} --network baseGoerli`
  );

  console.log("ERC1155AB deployed to:", erc1155ab.address);
  console.log(`npx hardhat verify ${erc1155ab.address} --network baseGoerli`);

  console.log("ABRoyalty deployed to:", abRoyalty.address);
  console.log(`npx hardhat verify ${abRoyalty.address} --network baseGoerli`);

  console.log("ABVerifier deployed to:", abVerifier.address);
  console.log(
    `npx hardhat verify ${abVerifier.address} ${AB_VERIFIER_ARGS.map(
      (a) => `"${a}"`
    ).join(" ")} --network baseGoerli`
  );

  console.log("ABDataRegistry deployed to:", abDataRegistry.address);
  console.log(
    `npx hardhat verify ${abDataRegistry.address} ${AB_DATA_REGISTRY_ARGS.map(
      (a) => `"${a}"`
    ).join(" ")} --network baseGoerli`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
