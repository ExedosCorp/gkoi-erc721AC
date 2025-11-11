// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {GKoiBattlecards} from "../src/GKoiBattlecards.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployGKoiBattlecards is Script {
    function run() external returns (GKoiBattlecards) {
        HelperConfig config = new HelperConfig();
        (uint256 deployerPrivateKey, address royaltyReceiver, uint96 royalty, string memory contractURI) =
            config.activeNetworkConfig();

        vm.startBroadcast(deployerPrivateKey);
        GKoiBattlecards gKoiBattlecards =
            new GKoiBattlecards(royaltyReceiver, royalty, "GKoi Battlecards", "GKOI", contractURI);
        vm.stopBroadcast();

        console.log("GKoiBattlecards deployed to:", address(gKoiBattlecards));
        return gKoiBattlecards;
    }
}
