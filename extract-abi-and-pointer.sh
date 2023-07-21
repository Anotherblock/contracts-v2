#!/bin/bash

chains=(420 84531 8453)

# Loop over each chainID
for chain in ${chains[@]}; do

  output_folder="abi/$chain"
  input_file="broadcast/deploy-platform.s.sol/$chain/run-latest.json"

  # Create the output folder if it does not exist
  mkdir -p "$output_folder"

  # Extract contract names and addresses using jq
  contracts=$(jq -c '.transactions[] | {name: .contractName, address: .contractAddress}' "$input_file")

  # Loop over each contract and create a JSON file with the contract address
  for contract in $contracts; do
    name=$(echo "$contract" | jq -r '.name')
    address=$(echo "$contract" | jq -r '.address')
    contract_json_file="out/$name.sol/$name.json"

    abi=$(jq -r '.abi' "$contract_json_file")

    echo "{\"address\": \"$address\", \"abi\": $abi}" > "$output_folder/${name}.json"
  done
done
