// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script} from "forge-std/Script.sol";

contract GKoiBattlecardsHelperConfig is Script {
    struct NetworkConfig {
        uint256 deployerPrivateKey;
        address royaltyReceiver;
        uint96 royalty;
        string contractURI;
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

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_DEPLOYER_PRIVATE_KEY");
        address royaltyReceiverAddress = vm.envAddress("SEPOLIA_ROYALTY_RECEIVER_ADDRESS");
        string memory contractURI = vm.envString("SEPOLIA_CONTRACT_URI");
        uint96 royalty = 500; // 5%

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            royaltyReceiver: royaltyReceiverAddress,
            royalty: royalty,
            contractURI: contractURI
        });
        return config;
    }

    function getEthConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("MAINNET_DEPLOYER_PRIVATE_KEY");
        address royaltyReceiverAddress = vm.envAddress("MAINNET_ROYALTY_RECEIVER_ADDRESS");
        string memory contractURI = vm.envString("MAINNET_CONTRACT_URI");
        uint96 royalty = 500; // 5%

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            royaltyReceiver: royaltyReceiverAddress,
            royalty: royalty,
            contractURI: contractURI
        });
        return config;
    }

    function getAnvilConfig() public view returns (NetworkConfig memory) {
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_DEPLOYER_PRIVATE_KEY");
        address royaltyReceiverAddress = vm.envAddress("SEPOLIA_ROYALTY_RECEIVER_ADDRESS");
        string memory contractURI = vm.envString("SEPOLIA_CONTRACT_URI");
        uint96 royalty = 500; // 5%

        NetworkConfig memory config = NetworkConfig({
            deployerPrivateKey: deployerPrivateKey,
            royaltyReceiver: royaltyReceiverAddress,
            royalty: royalty,
            contractURI: contractURI
        });
        return config;
    }
}
