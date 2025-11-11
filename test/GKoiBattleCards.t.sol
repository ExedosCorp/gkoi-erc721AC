// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console, Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {GKoiBattlecards} from "../src/GKoiBattlecards.sol";
import {DeployGKoiBattlecards} from "../script/GKoiBattlecards.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract Helper is Script {
    address deployer;
    address royaltyReceiver;
    uint96 royalty;
    string contractURI;

    constructor() {
        HelperConfig config = new HelperConfig();
        (uint256 _deployerPrivateKey, address _royaltyReceiver, uint96 _royalty, string memory _contractURI) =
            config.activeNetworkConfig();

        deployer = vm.addr(_deployerPrivateKey);
        royaltyReceiver = _royaltyReceiver;
        royalty = _royalty;
        contractURI = _contractURI;
    }
}

contract GKoiBattlecardsTest is Test, Helper {
    GKoiBattlecards gKoiBattlecards;
    HelperConfig config = new HelperConfig();

    function setUp() public {
        DeployGKoiBattlecards deployGKoiBattlecards = new DeployGKoiBattlecards();
        gKoiBattlecards = deployGKoiBattlecards.run();
    }

    function test_ContractURI() public view {
        string memory uri = gKoiBattlecards.contractURI();
        assert(bytes(uri).length > 0);
        assertEq(bytes(uri), bytes(contractURI));
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
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattlecards.mint(to, quantity);
    }
    
    function testRevert_Mint_ExceedsMaxSupply() public {
        address to = address(0x123);
        uint256 quantity = gKoiBattlecards.MAX_SUPPLY() + 1;
        vm.prank(deployer);
        vm.expectRevert("Exceeds max supply");
        gKoiBattlecards.mint(to, quantity);
    }

    function test_SafeMint() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattlecards.safeMint(to, quantity);

        assertEq(gKoiBattlecards.balanceOf(to), quantity);
    }

    function testRevert_SafeMint_NotOwner() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattlecards.safeMint(to, quantity);
    }

    function testRevert_SafeMint_ExceedsMaxSupply() public {
        address to = address(0x123);
        uint256 quantity = gKoiBattlecards.MAX_SUPPLY() + 1;
        vm.prank(deployer);
        vm.expectRevert("Exceeds max supply");
        gKoiBattlecards.safeMint(to, quantity);
    }

    function test_nameAndSymbol() public view {
        string memory name = gKoiBattlecards.name();
        string memory symbol = gKoiBattlecards.symbol();

        assertEq(name, "GKoi Battlecards");
        assertEq(symbol, "GKOI");
    }

    function test_TotalSupply() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        assertEq(gKoiBattlecards.totalSupply(), quantity);
    }

    function test_MaxSupply() public view {
        uint256 maxSupply = gKoiBattlecards.MAX_SUPPLY();
        assertEq(maxSupply, 10000);
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

    function test_SupportsInterface() public view {
        bool supportsERC721 = gKoiBattlecards.supportsInterface(type(IERC721).interfaceId);
        bool supportsERC2981 = gKoiBattlecards.supportsInterface(type(IERC2981).interfaceId);

        assertTrue(supportsERC721);
        assertTrue(supportsERC2981);
    }

    function test_setDefaultRoyalty() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(deployer);
        gKoiBattlecards.setDefaultRoyalty(newReceiver, newRoyalty);

        uint256 salePrice = 10000; // in wei
        (, uint256 royaltyAmount) = gKoiBattlecards.royaltyInfo(1, salePrice);

        assertEq(royaltyAmount, (salePrice * newRoyalty) / 10000);
    }

    function testRevert_setDefaultRoyalty_NotOwner() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(address(0x456));
        vm.expectRevert();
        gKoiBattlecards.setDefaultRoyalty(newReceiver, newRoyalty);
    }

    function test_setTokenRoyalty() public {
        uint256 tokenId = 1;
        address newReceiver = address(0x789);
        uint96 newRoyalty = 400; // 4%

        vm.prank(deployer);
        gKoiBattlecards.setTokenRoyalty(tokenId, newReceiver, newRoyalty);

        uint256 salePrice = 10000; // in wei
        (, uint256 royaltyAmount) = gKoiBattlecards.royaltyInfo(tokenId, salePrice);

        assertEq(royaltyAmount, (salePrice * newRoyalty) / 10000);
    }

    function testRevert_setTokenRoyalty_NotOwner() public {
        uint256 tokenId = 1;
        address newReceiver = address(0x789);
        uint96 newRoyalty = 400; // 4%

        vm.prank(address(0x456));
        vm.expectRevert();
        gKoiBattlecards.setTokenRoyalty(tokenId, newReceiver, newRoyalty);
    }

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

        uint256 tokenId = 0; // First token minted
        address owner = gKoiBattlecards.ownerOf(tokenId);
        assertEq(owner, to);
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
        gKoiBattlecards.setBaseURI(string(abi.encodePacked(contractURI, "/")));
        gKoiBattlecards.mint(to, quantity);
        vm.stopPrank();

        uint256 tokenId = 0; // First token minted
        string memory uri = gKoiBattlecards.tokenURI(tokenId);
        assert(bytes(uri).length > 0);
    }

    function testRevert_OwnerOf_NonExistentToken() public {
        uint256 nonExistentTokenId = 9999;
        vm.expectRevert("OwnerQueryForNonexistentToken()");
        gKoiBattlecards.ownerOf(nonExistentTokenId);
    }

    function test_getApproved() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(to, quantity);

        uint256 tokenId = 0; // First token minted
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

    function test_approve() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        uint256 tokenId = 0; // First token minted
        vm.prank(deployer);
        gKoiBattlecards.approve(to, tokenId);

        address approved = gKoiBattlecards.getApproved(tokenId);
        assertEq(approved, to);
    }

    function testRevert_Approve_NotOwnerNorApproved() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattlecards.mint(deployer, quantity);

        uint256 tokenId = 0; // First token minted
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

    function test_renounceOwnership () public {
        vm.prank(deployer);
        gKoiBattlecards.renounceOwnership();

        address owner = gKoiBattlecards.owner();
        assertEq(owner, address(0));
    }

    function testRevert_renounceOwnership_NotOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattlecards.renounceOwnership();
    }

    function test_setApprovalForAll() public {
        address operator = address(0x123);
        vm.prank(deployer);
        gKoiBattlecards.setApprovalForAll(operator, true);

        bool isApproved = gKoiBattlecards.isApprovedForAll(deployer, operator);
        assertTrue(isApproved);
    }

    function test_transferOwnership () public {
        address newOwner = address(0x123);
        vm.prank(deployer);
        gKoiBattlecards.transferOwnership(newOwner);

        address owner = gKoiBattlecards.owner();
        assertEq(owner, newOwner);
    }

    function testRevert_transferOwnership_NotOwner() public {
        address newOwner = address(0x123);
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattlecards.transferOwnership(newOwner);
    }

    function test_Fallback() public {
        (bool success, ) = address(gKoiBattlecards).call{value: 1 ether}("");
        assertFalse(success);
    }
}
