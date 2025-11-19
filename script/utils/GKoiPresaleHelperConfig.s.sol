// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";
// import {DeployGKoiBattlecards} from "../GKoiBattlecards.s.sol";
// import {GKoiBattlecards} from "../../src/GKoiBattlecards.sol";

contract GKoiPresaleHelperConfig is Script {
    struct NetworkConfig {
        uint256 deployerPrivateKey;
        uint256 validatorPrivateKey;
        address gkoiBattlecardsAddress;
        address owner;
        address validator;
        uint256 initialPrice;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        // activeNetworkConfig = getSepoliaEthConfig();
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getEthConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getEthConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_DEPLOYER_PRIVATE_KEY");
        uint256 validatorPrivateKey = vm.envUint("MAINNET_VALIDATOR_PRIVATE_KEY");
        address gkoiBattlecardsAddress = vm.envAddress("MAINNET_GKOI_BATTLECARDS_ADDRESS");
        address owner = vm.envAddress("MAINNET_OWNER_ADDRESS");
        address validator = vm.envAddress("MAINNET_VALIDATOR_ADDRESS");
        uint256 initialPrice = vm.envUint("MAINNET_INITIAL_NFT_PRICE");

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            validatorPrivateKey: validatorPrivateKey,
            gkoiBattlecardsAddress: gkoiBattlecardsAddress,
            owner: owner,
            validator: validator,
            initialPrice: initialPrice
        });
        return config;
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_DEPLOYER_PRIVATE_KEY");
        uint256 validatorPrivateKey = vm.envUint("SEPOLIA_VALIDATOR_PRIVATE_KEY");
        address gkoiBattlecardsAddress = vm.envAddress("SEPOLIA_GKOI_BATTLECARDS_ADDRESS");
        address owner = vm.envAddress("SEPOLIA_OWNER_ADDRESS");
        address validator = vm.envAddress("SEPOLIA_VALIDATOR_ADDRESS");
        uint256 initialPrice = vm.envUint("SEPOLIA_INITIAL_NFT_PRICE");

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            validatorPrivateKey: validatorPrivateKey,
            gkoiBattlecardsAddress: gkoiBattlecardsAddress,
            owner: owner,
            validator: validator,
            initialPrice: initialPrice
        });
        return config;
    }

    function getAnvilConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_DEPLOYER_PRIVATE_KEY");
        uint256 validatorPrivateKey = vm.envUint("SEPOLIA_VALIDATOR_PRIVATE_KEY");
        address gkoiBattlecardsAddress = vm.envAddress("SEPOLIA_GKOI_BATTLECARDS_ADDRESS");
        address owner = vm.envAddress("SEPOLIA_OWNER_ADDRESS");
        address validator = vm.envAddress("SEPOLIA_VALIDATOR_ADDRESS");
        // uint256 initialPrice = vm.envUint("SEPOLIA_INITIAL_NFT_PRICE");

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            validatorPrivateKey: validatorPrivateKey,
            gkoiBattlecardsAddress: gkoiBattlecardsAddress,
            owner: owner,
            validator: validator,
            initialPrice: 10000000000000000 // 0.01 ETH
        });
        return config;
    }
}
