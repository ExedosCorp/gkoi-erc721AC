// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {GKoiPresale} from "../src/GKoiPresale.sol";
import {GKoiPresaleHelperConfig} from "./utils/GKoiPresaleHelperConfig.s.sol";

contract DeployGKoiPresale is Script {
    function run() external returns (GKoiPresale) {
        GKoiPresaleHelperConfig config = new GKoiPresaleHelperConfig();
        (uint256 deployerPrivateKey,,, address owner, address validator,) = config.activeNetworkConfig();

        vm.startBroadcast(deployerPrivateKey);
        GKoiPresale gKoiPresale = new GKoiPresale(owner, validator);

        console.log("GKoiPresale deployed to:", address(gKoiPresale));

        vm.stopBroadcast();
        return gKoiPresale;
    }
}
