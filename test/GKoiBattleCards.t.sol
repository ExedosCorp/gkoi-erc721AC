// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console, Test} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {GKoiBattleCards} from "../src/GKoiBattleCards.sol";
import {DeployGKoiBattleCards} from "../script/GKoiBattleCards.s.sol";
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

contract GKoiBattleCardsTest is Test, Helper {
    GKoiBattleCards gKoiBattleCards;
    HelperConfig config = new HelperConfig();

    function setUp() public {
        DeployGKoiBattleCards deployGKoiBattleCards = new DeployGKoiBattleCards();
        gKoiBattleCards = deployGKoiBattleCards.run();
    }

    function test_ContractURI() public view {
        string memory uri = gKoiBattleCards.contractURI();
        assert(bytes(uri).length > 0);
        assertEq(bytes(uri), bytes(contractURI));
    }

    function test_Mint() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattleCards.mint(to, quantity);

        assertEq(gKoiBattleCards.balanceOf(to), quantity);
    }

    function testRevert_Mint_NotOwner() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattleCards.mint(to, quantity);
    }
    
    function testRevert_Mint_ExceedsMaxSupply() public {
        address to = address(0x123);
        uint256 quantity = gKoiBattleCards.MAX_SUPPLY() + 1;
        vm.prank(deployer);
        vm.expectRevert("Exceeds max supply");
        gKoiBattleCards.mint(to, quantity);
    }

    function test_SafeMint() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattleCards.safeMint(to, quantity);

        assertEq(gKoiBattleCards.balanceOf(to), quantity);
    }

    function testRevert_SafeMint_NotOwner() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(address(0x456));
        vm.expectRevert("Ownable: caller is not the owner");
        gKoiBattleCards.safeMint(to, quantity);
    }

    function testRevert_SafeMint_ExceedsMaxSupply() public {
        address to = address(0x123);
        uint256 quantity = gKoiBattleCards.MAX_SUPPLY() + 1;
        vm.prank(deployer);
        vm.expectRevert("Exceeds max supply");
        gKoiBattleCards.safeMint(to, quantity);
    }

    function test_nameAndSymbol() public view {
        string memory name = gKoiBattleCards.name();
        string memory symbol = gKoiBattleCards.symbol();

        assertEq(name, "GKoi BattleCards");
        assertEq(symbol, "GKOI");
    }

    function test_TotalSupply() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattleCards.mint(to, quantity);

        assertEq(gKoiBattleCards.totalSupply(), quantity);
    }

    function test_MaxSupply() public view {
        uint256 maxSupply = gKoiBattleCards.MAX_SUPPLY();
        assertEq(maxSupply, 10000);
    }

    function test_Owner() public view {
        address owner = gKoiBattleCards.owner();
        assertEq(owner, deployer);
    }

    function test_RoyaltyInfo() public view {
        uint256 tokenId = 1;
        uint256 salePrice = 10000; // in wei
        (address receiver, uint256 royaltyAmount) = gKoiBattleCards.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, royaltyReceiver);
        assertEq(royaltyAmount, (salePrice * royalty) / 10000);
    }

    function test_SupportsInterface() public view {
        bool supportsERC721 = gKoiBattleCards.supportsInterface(type(IERC721).interfaceId);
        bool supportsERC2981 = gKoiBattleCards.supportsInterface(type(IERC2981).interfaceId);

        assertTrue(supportsERC721);
        assertTrue(supportsERC2981);
    }

    function test_setDefaultRoyalty() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(deployer);
        gKoiBattleCards.setDefaultRoyalty(newReceiver, newRoyalty);

        uint256 salePrice = 10000; // in wei
        (, uint256 royaltyAmount) = gKoiBattleCards.royaltyInfo(1, salePrice);

        assertEq(royaltyAmount, (salePrice * newRoyalty) / 10000);
    }

    function testRevert_setDefaultRoyalty_NotOwner() public {
        address newReceiver = address(0x789);
        uint96 newRoyalty = 300; // 3%

        vm.prank(address(0x456));
        vm.expectRevert();
        gKoiBattleCards.setDefaultRoyalty(newReceiver, newRoyalty);
    }

    function test_setTokenRoyalty() public {
        uint256 tokenId = 1;
        address newReceiver = address(0x789);
        uint96 newRoyalty = 400; // 4%

        vm.prank(deployer);
        gKoiBattleCards.setTokenRoyalty(tokenId, newReceiver, newRoyalty);

        uint256 salePrice = 10000; // in wei
        (, uint256 royaltyAmount) = gKoiBattleCards.royaltyInfo(tokenId, salePrice);

        assertEq(royaltyAmount, (salePrice * newRoyalty) / 10000);
    }

    function testRevert_setTokenRoyalty_NotOwner() public {
        uint256 tokenId = 1;
        address newReceiver = address(0x789);
        uint96 newRoyalty = 400; // 4%

        vm.prank(address(0x456));
        vm.expectRevert();
        gKoiBattleCards.setTokenRoyalty(tokenId, newReceiver, newRoyalty);
    }

    function test_BalanceOf() public {
        address to = address(0x123);
        uint256 quantity = 5;
        vm.prank(deployer);
        gKoiBattleCards.mint(to, quantity);

        uint256 balance = gKoiBattleCards.balanceOf(to);
        assertEq(balance, quantity);
    }

    function test_OwnerOf() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattleCards.mint(to, quantity);

        uint256 tokenId = 0; // First token minted
        address owner = gKoiBattleCards.ownerOf(tokenId);
        assertEq(owner, to);
    }

    function testRevert_BalanceOf_ZeroAddress() public {
        address zeroAddress = address(0);
        vm.expectRevert("BalanceQueryForZeroAddress()");
        gKoiBattleCards.balanceOf(zeroAddress);
    }

    function test_tokenURI() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.startPrank(deployer);
        gKoiBattleCards.setBaseURI(string(abi.encodePacked(contractURI, "/")));
        gKoiBattleCards.mint(to, quantity);
        vm.stopPrank();

        uint256 tokenId = 0; // First token minted
        string memory uri = gKoiBattleCards.tokenURI(tokenId);
        assert(bytes(uri).length > 0);
    }

    function testRevert_OwnerOf_NonExistentToken() public {
        uint256 nonExistentTokenId = 9999;
        vm.expectRevert("OwnerQueryForNonexistentToken()");
        gKoiBattleCards.ownerOf(nonExistentTokenId);
    }

    function test_getApproved() public {
        address to = address(0x123);
        uint256 quantity = 1;
        vm.prank(deployer);
        gKoiBattleCards.mint(to, quantity);

        uint256 tokenId = 0; // First token minted
        address approved = gKoiBattleCards.getApproved(tokenId);
        assertEq(approved, address(0));
    }

    function testRevert_getApproved_NonExistentToken() public {
        uint256 nonExistentTokenId = 9999;
        vm.expectRevert("ApprovalQueryForNonexistentToken()");
        gKoiBattleCards.getApproved(nonExistentTokenId);
    }

    function test_isApprovedForAll() public view {
        address owner = address(0x123);
        address operator = address(0x456);

        bool isApproved = gKoiBattleCards.isApprovedForAll(owner, operator);
        assertFalse(isApproved);
    }

    function test_Fallback() public {
        (bool success, ) = address(gKoiBattleCards).call{value: 1 ether}("");
        assertFalse(success);
    }
}
