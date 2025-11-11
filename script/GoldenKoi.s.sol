// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {GoldenKoi} from "../src/GoldenKoi.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployGoldenKoi is Script {
    function run() external returns(GoldenKoi) {

        HelperConfig config = new HelperConfig();
        (uint256 deployerPrivateKey, address royaltyReceiver, uint96 royalty, string memory contractURI) = config.activeNetworkConfig();

        vm.startBroadcast(deployerPrivateKey);
        GoldenKoi goldenKoi = new GoldenKoi(
            royaltyReceiver,
            royalty,
            "GoldenKoi",
            "GKOI",
            contractURI
        );
        vm.stopBroadcast();

        console.log("GoldenKoi deployed to:", address(goldenKoi));
        return goldenKoi;
    }
}