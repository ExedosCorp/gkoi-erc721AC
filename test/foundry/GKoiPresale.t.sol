// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {GKoiPresale} from "../../src/GKoiPresale.sol";
import {DeployGKoiPresale} from "../../script/DeployGKoiPresale.s.sol";
import {DeployGKoiBattlecards} from "../../script/DeployGKoiBattlecards.s.sol";
import {GKoiPresaleHelperConfig} from "../../script/utils/GKoiPresaleHelperConfig.s.sol";
import {GKoiBattlecards} from "../../src/GKoiBattlecards.sol";

contract Helper is Script {
    uint256 deployerPrivateKey;
    uint256 validatorPrivateKey;
    address owner;
    address validator;
    uint256 initialPrice;

    uint256 preMintedNftCount = 10_000;
    GKoiBattlecards gKoiBattlecards;

    bytes32 private constant _MESSAGE_TYPEHASH =
        keccak256("ClaimMessage(address account,uin256 amount,uint256 deadline,uin256 chainId)");

    event PurchasedPresale(address indexed buyer, uint256 quantity);

    constructor() {
        GKoiPresaleHelperConfig config = new GKoiPresaleHelperConfig();
        (
            uint256 _deployerPrivateKey,
            uint256 _validatorPrivateKey,,
            address _owner,
            address _validator,
            uint256 _initialPrice
        ) = config.activeNetworkConfig();

        deployerPrivateKey = _deployerPrivateKey;
        validatorPrivateKey = _validatorPrivateKey;
        owner = _owner;
        validator = _validator;
        initialPrice = _initialPrice;

        DeployGKoiBattlecards deployGKoiBattlecards = new DeployGKoiBattlecards();

        gKoiBattlecards = deployGKoiBattlecards.run();
        vm.prank(vm.addr(_deployerPrivateKey));
        gKoiBattlecards.updateTransfersPaused(false);
    }
}

contract GKoiPresaleTest is Test, Helper {
    GKoiPresale gKoiPresale;
    GKoiPresaleHelperConfig config = new GKoiPresaleHelperConfig();

    event PurchasedSale(address indexed buyer, uint256 tokenId, uint256 price);


    function setUp() public {
        DeployGKoiPresale deployGKoiPresale = new DeployGKoiPresale();
        gKoiPresale = deployGKoiPresale.run();

        vm.prank(vm.addr(deployerPrivateKey));
        gKoiBattlecards.mint(owner, preMintedNftCount);

        vm.startPrank(owner);
        gKoiPresale.setGkoiBattlecardsAddress(address(gKoiBattlecards));
        gKoiBattlecards.setApprovalForAll(address(gKoiPresale), true);
        vm.stopPrank();
    }

    function _generateSignature(GKoiPresale.ClaimMessage memory _message) internal view returns (bytes memory) {
        bytes32 digest = gKoiPresale.getClaimSignatureMessageHash(
            _message.account, _message.quantity, _message.ethValue, _message.deadline
        );
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, digest));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPrivateKey, prefixedHashMessage);
        bytes memory _signature = abi.encodePacked(r, s, v);
        return _signature;
    }

    function _depositNfts(uint256 _depositAmount) internal {
        uint256[] memory tokenIds = new uint256[](_depositAmount);
        for (uint256 i = 0; i < _depositAmount; i++) {
            tokenIds[i] = i + 1;
        }
        vm.prank(owner);
        gKoiPresale.depositAssets(tokenIds);
    }

    function test_setUp() public view {
        assertEq(gKoiPresale.hasRole(gKoiPresale.DEFAULT_ADMIN_ROLE(), owner), true);
        assertEq(gKoiPresale.hasRole(gKoiPresale.VALIDATOR_ROLE(), validator), true);
        assertEq(gKoiBattlecards.balanceOf(owner), preMintedNftCount);
        assertEq(gKoiBattlecards.isApprovedForAll(owner, address(gKoiPresale)), true);
    }

    function test_getAvailableTokenIds() public {
        uint256 _depositAmount = 100;
        _depositNfts(_depositAmount);

        uint256[] memory availableTokenIds = gKoiPresale.getAvailableTokenIds();

        assertEq(availableTokenIds.length, _depositAmount);
        for (uint256 i = 0; i < _depositAmount; i++) {
            assertEq(availableTokenIds[i], i + 1);
        }
    }

    function test_pause() public {
        vm.prank(owner);
        gKoiPresale.pause();
        assertTrue(gKoiPresale.paused());
    }

    function testRevert_pauseNotOwner() public {
        vm.expectRevert();
        vm.prank(validator);
        gKoiPresale.pause();
    }

    function test_unpause() public {
        vm.startPrank(owner);
        gKoiPresale.pause();
        gKoiPresale.unpause();
        assertFalse(gKoiPresale.paused());
        vm.stopPrank();
    }

    function testRevert_unpauseNotOwner() public {
        vm.expectRevert();
        vm.prank(owner);
        gKoiPresale.unpause();
    }

    function test_setGkoiBattlecardsAddress() public {
        address newAddress = address(0x123);
        vm.prank(owner);
        gKoiPresale.setGkoiBattlecardsAddress(newAddress);
        assertEq(address(gKoiPresale.GKOI_BATTLECARDS()), newAddress);
    }

    function testRevert_setGkoiBattlecardsAddressNotOwner() public {
        address newAddress = address(0x123);
        vm.expectRevert();
        vm.prank(validator);
        gKoiPresale.setGkoiBattlecardsAddress(newAddress);
    }

    function test_depositAssets() public {
        uint256 _depositAmount = 100;
        uint256 initialAvailableTokenIdsLength = gKoiPresale.getAvailableTokenIds().length;

        _depositNfts(_depositAmount);

        uint256 finalAvailableTokenIdsLength = gKoiPresale.getAvailableTokenIds().length;

        assertEq(initialAvailableTokenIdsLength + _depositAmount, finalAvailableTokenIdsLength);
    }

    function test_depositAssetsNotOwner() public {
        uint256 _depositAmount = 100;

        uint256[] memory tokenIds = new uint256[](_depositAmount);
        for (uint256 i = 0; i < _depositAmount; i++) {
            tokenIds[i] = i + 1;
        }

        vm.expectRevert();
        vm.prank(validator);
        gKoiPresale.depositAssets(tokenIds);
    }

    function test_buyPresale() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        uint256 _initialAvailableTokenIdsLength = gKoiPresale.getAvailableTokenIds().length;
        uint256 _initialContractEthBalance = address(gKoiPresale).balance;
        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);
        uint256 _initialUserEthBalance = account.balance;

        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );

        assertEq(gKoiPresale.presaleMinted(message.account), message.quantity);
        assertEq(gKoiBattlecards.balanceOf(message.account), message.quantity);
        assertEq(gKoiPresale.getAvailableTokenIds().length, _initialAvailableTokenIdsLength - message.quantity);
        assertEq(address(gKoiPresale).balance, _initialContractEthBalance + message.ethValue);
        assertEq(account.balance, _initialUserEthBalance - message.ethValue);
    }

    function test_buyPresale_EmitLog() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);

        vm.prank(message.account);
        vm.expectEmit(true, true, true, false);
        emit PurchasedSale(message.account, 1, message.ethValue / message.quantity);
        vm.expectEmit(true, true, true, false);
        emit PurchasedSale(message.account, 2, message.ethValue / message.quantity);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function testRevert_buyPresale_InvalidSignature() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);
        address invalidAccount = address(0x789);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(invalidAccount, message.ethValue);

        vm.expectRevert("GKoiPresale: Invalid signature");
        vm.prank(invalidAccount);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function testRevert_buyPresale_InsufficientEth() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue - 0.1 ether);

        vm.expectRevert("GKoiPresale: Incorrect ETH amount");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue - 0.1 ether}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function testRevert_buyPresale_SignatureExpired() public {
        uint256 _depositAmount = 10;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message =
            GKoiPresale.ClaimMessage({account: account, quantity: 2, ethValue: 0.5 ether, deadline: 0});

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);
        vm.expectRevert("GKoiPresale: Signature expired");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function testRevert_buyPresale_SignatureTooFarInFuture() public {
        uint256 _depositAmount = 10;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 5.5 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);
        vm.expectRevert("GKoiPresale: Signature deadline too far in future");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function testRevert_buyPresale_NotEnoughNfts() public {
        uint256 _depositAmount = 1;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);
        vm.expectRevert("GKoiPresale: Not enough NFTs available");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function test_buyPresale_SignatureUsedMultipleTimes() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue * 2);
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );

        vm.expectRevert("GKoiPresale: Signature already used");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function test_buyPresale_WhenPaused() public {
        uint256 _depositAmount = 1_000;
        _depositNfts(_depositAmount);

        address account = address(0x456);

        GKoiPresale.ClaimMessage memory message = GKoiPresale.ClaimMessage({
            account: account, quantity: 2, ethValue: 0.5 ether, deadline: block.timestamp + 1 minutes
        });

        bytes memory _signature = _generateSignature(message);

        deal(message.account, message.ethValue);

        vm.prank(owner);
        gKoiPresale.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(message.account);
        gKoiPresale.buyPresale{value: message.ethValue}(
            _signature, message.quantity, message.ethValue, message.deadline
        );
    }

    function test_getClaimSignatureMessageHash() public {
        address account = address(0x456);
        uint256 quantity = 2;
        uint256 ethValue = 0.5 ether;
        uint256 deadline = block.timestamp + 1 minutes;

        bytes32 expectedHash = keccak256(
            abi.encode(
                keccak256(
                    "ClaimMessage(address account,uint256 quantity,uint256 ethValue,uint256 deadline, uint256 chainId)"
                ),
                account,
                quantity,
                ethValue,
                deadline,
                block.chainid
            )
        );

        bytes32 actualHash = gKoiPresale.getClaimSignatureMessageHash(account, quantity, ethValue, deadline);

        assertEq(expectedHash, actualHash);
    }

    function test_withdraw() public {
        address recipient = address(1);
        uint256 initialRecipientBalance = recipient.balance;

        // Fund the contract with some ETH
        uint256 fundAmount = 1 ether;
        vm.deal(address(gKoiPresale), fundAmount);

        vm.prank(owner);
        gKoiPresale.withdraw(recipient);

        uint256 finalRecipientBalance = recipient.balance;
        assertEq(finalRecipientBalance, initialRecipientBalance + fundAmount);
    }

    function testRevert_withdrawNotOwner() public {
        address recipient = address(1);

        vm.expectRevert();
        vm.prank(validator);
        gKoiPresale.withdraw(recipient);
    }

    function test_withdrawUnsoldTokens() public {
        uint256 initialRecipientBalance = gKoiBattlecards.balanceOf(address(1));
        address recipient = address(1);

        uint256 depositAmount = 100;
        uint256[] memory tokenIds = new uint256[](depositAmount);
        for (uint256 i = 0; i < depositAmount; i++) {
            tokenIds[i] = i + 1;
        }

        vm.startPrank(owner);
        gKoiPresale.depositAssets(tokenIds);
        gKoiPresale.withdrawUnsoldTokens(recipient);
        vm.stopPrank();

        uint256 finalRecipientBalance = gKoiBattlecards.balanceOf(recipient);
        assertEq(finalRecipientBalance, initialRecipientBalance + depositAmount);
    }

    function testRevert_withdrawUnsoldTokensNotOwner() public {
        vm.expectRevert();
        vm.prank(validator);
        gKoiPresale.withdrawUnsoldTokens(address(1));
    }

    function test_receive() public {
        uint256 initialContractBalance = address(gKoiPresale).balance;
        uint256 sendAmount = 1 ether;

        deal(validator, sendAmount);
        vm.prank(validator);
        (bool success,) = address(gKoiPresale).call{value: sendAmount}("");
        require(success, "Transfer failed.");

        uint256 finalContractBalance = address(gKoiPresale).balance;

        assertEq(finalContractBalance, initialContractBalance + sendAmount);
    }

    function test_fallback() public {
        uint256 initialContractBalance = address(gKoiPresale).balance;
        uint256 sendAmount = 1 ether;

        deal(validator, sendAmount);
        vm.prank(validator);
        (bool success,) = address(gKoiPresale).call{value: sendAmount}(abi.encodeWithSignature("nonExistentFunction()"));
        require(success, "Transfer failed.");

        uint256 finalContractBalance = address(gKoiPresale).balance;

        assertEq(finalContractBalance, initialContractBalance + sendAmount);
    }
}
