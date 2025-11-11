// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {GKoiBattleCards} from "../src/GKoiBattleCards.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployGKoiBattleCards is Script {
    function run() external returns(GKoiBattleCards) {

        HelperConfig config = new HelperConfig();
        (uint256 deployerPrivateKey, address royaltyReceiver, uint96 royalty, string memory contractURI) = config.activeNetworkConfig();

        vm.startBroadcast(deployerPrivateKey);
        GKoiBattleCards gKoiBattleCards = new GKoiBattleCards(
            royaltyReceiver,
            royalty,
            "GKoi Battle Cards",
            "GKOI",
            contractURI
        );
        vm.stopBroadcast();

        console.log("GKoiBattleCards deployed to:", address(gKoiBattleCards));
        return gKoiBattleCards;
    }
}