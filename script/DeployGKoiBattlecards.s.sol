// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Script, console} from "forge-std/Script.sol";
import {GKoiBattlecards} from "../src/GKoiBattlecards.sol";
import {GKoiBattlecardsHelperConfig} from "./utils/GKoiBattlecardsHelperConfig.s.sol";
import {ISeaDropTokenContractMetadata} from "../src/interfaces/ISeaDropTokenContractMetadata.sol";

contract DeployGKoiBattlecards is Script {
    function run() external returns (GKoiBattlecards) {
        GKoiBattlecardsHelperConfig config = new GKoiBattlecardsHelperConfig();
        (uint256 deployerPrivateKey, address royaltyReceiver, uint96 royalty, string memory contractURI) =
            config.activeNetworkConfig();

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5; // SeaDrop address
        vm.startBroadcast(deployerPrivateKey);
        GKoiBattlecards gKoiBattlecards = new GKoiBattlecards("GKOI Battlecards", "GKOI", allowedSeaDrop);

        console.log("GKoiBattlecards deployed to:", address(gKoiBattlecards));
        console.log("Deployer address:", vm.addr(deployerPrivateKey));

        gKoiBattlecards.setContractURI(contractURI);

        gKoiBattlecards.setRoyaltyInfo(
            ISeaDropTokenContractMetadata.RoyaltyInfo({royaltyAddress: royaltyReceiver, royaltyBps: royalty})
        );

        gKoiBattlecards.setMaxSupply(10_000);

        vm.stopBroadcast();
        return gKoiBattlecards;
    }
}
