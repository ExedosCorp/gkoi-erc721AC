// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
// import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
// import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

import {GKoiBattlecards} from "../../src/GKoiBattlecards.sol";
import {DeployGKoiBattlecards} from "../../script/DeployGKoiBattlecards.s.sol";
import {GKoiBattlecardsHelperConfig} from "../../script/utils/GKoiBattlecardsHelperConfig.s.sol";
import {ISeaDropTokenContractMetadata} from "../../src/interfaces/ISeaDropTokenContractMetadata.sol";

contract Helper is Script {
    address deployer;
    address royaltyReceiver;
    uint96 royalty;
    string contractUri;

    constructor() {
        GKoiBattlecardsHelperConfig config = new GKoiBattlecardsHelperConfig();
        (uint256 _deployerPrivateKey, address _royaltyReceiver, uint96 _royalty, string memory _contractUri) =
            config.activeNetworkConfig();

        deployer = vm.addr(_deployerPrivateKey);
        royaltyReceiver = _royaltyReceiver;
        royalty = _royalty;
        contractUri = _contractUri;
    }
}

contract GKoiBattlecardsTest is Test, Helper {
    GKoiBattlecards gKoiBattlecards;
    GKoiBattlecardsHelperConfig config = new GKoiBattlecardsHelperConfig();

    function setUp() public {
        DeployGKoiBattlecards deployGKoiBattlecards = new DeployGKoiBattlecards();
        gKoiBattlecards = deployGKoiBattlecards.run();

        vm.startPrank(deployer);
        gKoiBattlecards.updateTransfersPaused(false);
        vm.stopPrank();
    }

    function test_nameAndSymbol() public view {
        string memory name = gKoiBattlecards.name();
        string memory symbol = gKoiBattlecards.symbol();

        assertEq(name, "GKOI Battlecards");
        assertEq(symbol, "GKOI");
    }

    function test_TotalSupply() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        assertEq(gKoiBattlecards.totalSupply(), quantity);
    }

    function test_MaxSupply() public {
        uint256 maxSupply = gKoiBattlecards.maxSupply();
        assertEq(maxSupply, 10000);
    }

    function testRevert_MaxSupplyAlreadySet() public {
        vm.expectRevert("MaxSupplyAlreadySet()");
        vm.prank(deployer);
        gKoiBattlecards.setMaxSupply(20000);
        vm.stopPrank();
    }

    function test_Owner() public view {
        address owner = gKoiBattlecards.owner();
        assertEq(owner, deployer);
    }

    function test_RoyaltyInfo() public view {
        uint256 tokenId = 1;
        uint256 salePrice = 10000; // in wei
        (address receiver, uint256 royaltyAmount) = gKoiBattlecards.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, (salePrice * royalty) / 10000);
    }

    function test_setRoyaltyInfo() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(deployer);
        gKoiBattlecards.setRoyaltyInfo(
            ISeaDropTokenContractMetadata.RoyaltyInfo({royaltyAddress: newReceiver, royaltyBps: newRoyalty})
        );

        uint256 salePrice = 10000; // in wei
        (, uint256 royaltyAmount) = gKoiBattlecards.royaltyInfo(1, salePrice);

        assertEq(royaltyAmount, (salePrice * newRoyalty) / 10000);
    }

    function testRevert_setRoyaltyInfo_NotOwner() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(address(0x456));
        vm.expectRevert("OnlyOwner()");
        gKoiBattlecards.setRoyaltyInfo(
            ISeaDropTokenContractMetadata.RoyaltyInfo({royaltyAddress: newReceiver, royaltyBps: newRoyalty})
        );
    }

    function test_ContractUri() public view {
        string memory uri = gKoiBattlecards.contractURI();
        assert(bytes(uri).length > 0);
        assertEq(bytes(uri), bytes(contractUri));
    }

    function test_updateTransfersPaused() public {
        vm.startPrank(deployer);
        gKoiBattlecards.updateTransfersPaused(true);
        assertTrue(gKoiBattlecards.transfersPaused());

        gKoiBattlecards.updateTransfersPaused(false);
        assertFalse(gKoiBattlecards.transfersPaused());
        vm.stopPrank();
    }

    function testRevert_updateTransfersPaused_NotOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert("OnlyOwner()");
        gKoiBattlecards.updateTransfersPaused(true);
    }

    function testRevert_updateTransfersPaused_TransfersPaused() public {
        vm.prank(deployer);
        gKoiBattlecards.updateTransfersPaused(true);

        vm.expectRevert("TransfersPaused()");
        vm.prank(deployer);
        gKoiBattlecards.approve(address(0x123), 1);
    }

    function test_Mint() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        assertEq(gKoiBattlecards.balanceOf(to), quantity);
    }

    function testRevert_Mint_NotOwner() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(address(0x456));
        vm.expectRevert("OnlyOwner()");
        gKoiBattlecards.mint(to, quantity);
    }

    function testRevert_Mint_ExceedsMaxSupply() public {
        address to = address(0x123);
        uint256 quantity = gKoiBattlecards.maxSupply() + 1;
        vm.prank(deployer);
        vm.expectRevert();
        gKoiBattlecards.mint(to, quantity);
    }

    function testRevert_Mint_TransfersPaused() public {
        vm.startPrank(deployer);
        gKoiBattlecards.updateTransfersPaused(true);

        address to = address(0x123);
        uint256 quantity = 5;
        vm.expectRevert("TransfersPaused()");
        gKoiBattlecards.mint(to, quantity);
        vm.stopPrank();
    }

    // // function test_SupportsInterface() public view {
    // //     bool supportsERC721 = gKoiBattlecards.supportsInterface(type(IERC721).interfaceId);
    // //     bool supportsERC2981 = gKoiBattlecards.supportsInterface(type(IERC2981).interfaceId);

    // //     assertTrue(supportsERC721);
    // //     assertTrue(supportsERC2981);
    // // }

    function test_BalanceOf() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        uint256 balance = gKoiBattlecards.balanceOf(to);
        assertEq(balance, quantity);
    }

    function test_OwnerOf() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        uint256 tokenId = 1; // First token minted
        address owner = gKoiBattlecards.ownerOf(tokenId);
        assertEq(owner, to);
    }

    function testRevert_OwnerOf_NonExistentToken() public {
        uint256 nonExistentTokenId = 9999;
        vm.expectRevert("OwnerQueryForNonexistentToken()");
        gKoiBattlecards.ownerOf(nonExistentTokenId);
    }

    function testRevert_BalanceOf_ZeroAddress() public {
        address zeroAddress = address(0);
        vm.expectRevert("BalanceQueryForZeroAddress()");
        gKoiBattlecards.balanceOf(zeroAddress);
    }

    function test_tokenURI() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.startPrank(deployer);
        gKoiBattlecards.setBaseURI(string(abi.encodePacked(contractUri, "/")));
        gKoiBattlecards.mint(to, quantity);
        vm.stopPrank();

        uint256 tokenId = 1; // First token minted
        string memory uri = gKoiBattlecards.tokenURI(tokenId);
        assert(bytes(uri).length > 0);
    }

    function test_getApproved() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        uint256 tokenId = 1; // First token minted
        address approved = gKoiBattlecards.getApproved(tokenId);
        assertEq(approved, address(0));
    }

    function testRevert_getApproved_NonExistentToken() public {
        uint256 nonExistentTokenId = 9999;
        vm.expectRevert("ApprovalQueryForNonexistentToken()");
        gKoiBattlecards.getApproved(nonExistentTokenId);
    }

    function test_isApprovedForAll() public view {
        address owner = address(0x123);
        address operator = address(0x456);

        bool isApproved = gKoiBattlecards.isApprovedForAll(owner, operator);
        assertFalse(isApproved);
    }

    function test_setApprovalForAll_and_isApprovedForAll() public {
        address operator = address(0x123);
        vm.prank(deployer);
        gKoiBattlecards.setApprovalForAll(operator, true);

        bool isApproved = gKoiBattlecards.isApprovedForAll(deployer, operator);
        assertTrue(isApproved);
    }

    function testRevert_SetApprovalForAll_TransfersPaused() public {
        vm.startPrank(deployer);
        gKoiBattlecards.updateTransfersPaused(true);

        address operator = address(0x123);
        vm.expectRevert("TransfersPaused()");
        gKoiBattlecards.setApprovalForAll(operator, true);
        vm.stopPrank();
    }

    function test_approve() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        uint256 tokenId = 1; // First token minted
        vm.prank(deployer);
        gKoiBattlecards.approve(to, tokenId);

        address approved = gKoiBattlecards.getApproved(tokenId);
        assertEq(approved, to);
    }

    function testRevert_Approve_TransfersPaused() public {
        vm.startPrank(deployer);

        address to = address(0x123);
        uint256 quantity = 1;
        gKoiBattlecards.mint(deployer, quantity);

        gKoiBattlecards.updateTransfersPaused(true);

        uint256 tokenId = 1; // First token minted
        vm.expectRevert("TransfersPaused()");
        gKoiBattlecards.approve(to, tokenId);
        vm.stopPrank();
    }

    function testRevert_Approve_NotOwnerNorApproved() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        uint256 tokenId = 1; // First token minted
        vm.prank(address(0x456));
        vm.expectRevert("ApprovalCallerNotOwnerNorApproved()");
        gKoiBattlecards.approve(to, tokenId);
    }

    function testRevert_Approve_NonExistentToken() public {
        address to = address(0x123);
        uint256 nonExistentTokenId = 9999;
        vm.prank(deployer);
        vm.expectRevert("OwnerQueryForNonexistentToken()");
        gKoiBattlecards.approve(to, nonExistentTokenId);
    }

    function test_safeTransferFrom() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.startPrank(deployer);
        gKoiBattlecards.mint(deployer, quantity);
        gKoiBattlecards.approve(to, tokenId);
        vm.stopPrank();

        vm.prank(to);
        gKoiBattlecards.safeTransferFrom(deployer, to, tokenId);

        address owner = gKoiBattlecards.ownerOf(tokenId);
        assertEq(owner, to);
    }

    function testRevert_safeTransferFrom_TransfersPaused() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.startPrank(deployer);
        gKoiBattlecards.mint(deployer, quantity);
        gKoiBattlecards.approve(to, tokenId);
        gKoiBattlecards.updateTransfersPaused(true);
        vm.stopPrank();

        vm.prank(to);
        vm.expectRevert("TransfersPaused()");
        gKoiBattlecards.safeTransferFrom(deployer, to, tokenId);
    }

    function testRevert_safeTransferFrom_NotOwnerNorApproved() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        vm.prank(to);
        vm.expectRevert("TransferCallerNotOwnerNorApproved()");
        gKoiBattlecards.safeTransferFrom(deployer, to, tokenId);
    }

    function test_transferFrom() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.startPrank(deployer);
        gKoiBattlecards.mint(deployer, quantity);
        gKoiBattlecards.approve(to, tokenId);
        vm.stopPrank();

        vm.prank(to);
        gKoiBattlecards.transferFrom(deployer, to, tokenId);

        address owner = gKoiBattlecards.ownerOf(tokenId);
        assertEq(owner, to);
    }

    function testRevert_transferFrom_TransfersPaused() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.startPrank(deployer);
        gKoiBattlecards.mint(deployer, quantity);
        gKoiBattlecards.approve(to, tokenId);
        gKoiBattlecards.updateTransfersPaused(true);
        vm.stopPrank();

        vm.prank(to);
        vm.expectRevert("TransfersPaused()");
        gKoiBattlecards.transferFrom(deployer, to, tokenId);
    }

    function testRevert_transferFrom_NotOwnerNorApproved() public {
        address to = address(0x123);

        uint256 quantity = 1;
        uint256 tokenId = 1; // First token minted

        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        vm.prank(to);
        vm.expectRevert("TransferCallerNotOwnerNorApproved()");
        gKoiBattlecards.transferFrom(deployer, to, tokenId);
    }

    function test_renounceOwnership() public {
        vm.prank(deployer);
        gKoiBattlecards.renounceOwnership();

        address owner = gKoiBattlecards.owner();
        assertEq(owner, address(0));
    }

    function testRevert_renounceOwnership_NotOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert("OnlyOwner()");
        gKoiBattlecards.renounceOwnership();
    }

    // function test_transferOwnership() public {
    //     address newOwner = address(0x123);
    //     vm.prank(deployer);
    //     gKoiBattlecards.transferOwnership(newOwner);

    //     address owner = gKoiBattlecards.owner();
    //     assertEq(owner, newOwner);
    // }

    // function testRevert_transferOwnership_NotOwner() public {
    //     address newOwner = address(0x123);
    //     vm.prank(address(0x456));
    //     vm.expectRevert("OnlyOwner()");
    //     gKoiBattlecards.transferOwnership(newOwner);
    // }

    function test_Fallback() public {
        (bool success,) = address(gKoiBattlecards).call{value: 1 ether}("");
        assertFalse(success);
    }
}
