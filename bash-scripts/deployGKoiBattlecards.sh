#!/bin/bash
source .env
clear && echo "Deploying GKoiBattlecards Contract..." && sleep 1
forge script script/DeployGKoiBattlecards.s.sol:DeployGKoiBattlecards --rpc-url $MAINNET_RPC_URL --verify -vvvv --broadcast
# forge script script/DeployGKoiBattlecards.s.sol:DeployGKoiBattlecards --rpc-url $SEPOLIA_RPC_URL --verify -vvvv --broadcast
