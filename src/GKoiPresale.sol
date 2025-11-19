// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console} from "forge-std/Console.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Pausable} from "openzeppelin-contracts/security/Pausable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC721Holder} from "openzeppelin-contracts/token/ERC721/utils/ERC721Holder.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {GKoiBattlecards} from "./GKoiBattlecards.sol";

contract GKoiPresale is AccessControl, ReentrancyGuard, Pausable, ERC721Holder {
    uint256 private immutable _CHAIN_ID = block.chainid;
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    GKoiBattlecards public GKOI_BATTLECARDS;
    uint256[] private _availableTokenIds;

    mapping(address => uint256) public presaleMinted;
    mapping(bytes => bool) private _usedSignatures;

    event PurchasedSale(address indexed buyer, uint256 tokenId, uint256 price);

    struct ClaimMessage {
        address account;
        uint256 quantity;
        uint256 ethValue;
        uint256 deadline;
    }

    constructor(address owner, address validator) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(VALIDATOR_ROLE, validator);
    }

    receive() external payable {}

    fallback() external payable {}

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setGkoiBattlecardsAddress(address gkoiBattlecardsAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        GKOI_BATTLECARDS = GKoiBattlecards(gkoiBattlecardsAddress);
    }

    function getAvailableTokenIds() external view returns (uint256[] memory) {
        return _availableTokenIds;
    }

    function depositAssets(uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address sender = msg.sender;
        address recipient = address(this);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            GKOI_BATTLECARDS.safeTransferFrom(sender, recipient, tokenId);
            _availableTokenIds.push(tokenId);
        }
    }

    function _transferAsset(address _to, uint256 _quantity, uint256 _price, bool _emitLog) private {
        require(_availableTokenIds.length >= _quantity, "GKoiPresale: Not enough NFTs available");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _availableTokenIds[_availableTokenIds.length - 1];
            _availableTokenIds.pop();
            GKOI_BATTLECARDS.safeTransferFrom(address(this), _to, tokenId);
            if (_emitLog) emit PurchasedSale(msg.sender, tokenId, _price);
    
        }
    }

    function buyPresale(bytes calldata _signature, uint256 _quantity, uint256 _ethValue, uint256 _deadline)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(_quantity > 0, "GKoiPresale: Quantity > Zero");
        require(msg.value >= _ethValue, "GKoiPresale: Incorrect ETH amount");
        require(block.timestamp <= _deadline, "GKoiPresale: Signature expired");
        require(_deadline <= block.timestamp + 5 minutes, "GKoiPresale: Signature deadline too far in future");
        require(!_usedSignatures[_signature], "GKoiPresale: Signature already used");

        ClaimMessage memory message =
            ClaimMessage({account: msg.sender, quantity: _quantity, ethValue: _ethValue, deadline: _deadline});
        address signer = _recoverAddress(message, _signature);
        require(hasRole(VALIDATOR_ROLE, signer), "GKoiPresale: Invalid signature");

        _usedSignatures[_signature] = true;
        presaleMinted[msg.sender] += _quantity;
        _transferAsset(msg.sender, _quantity, _ethValue / _quantity, true);
    }

    function getClaimSignatureMessageHash(address account, uint256 quantity, uint256 ethValue, uint256 deadline)
        public
        view
        returns (bytes32)
    {
        bytes32 _hashedMessage = keccak256(
            abi.encode(
                keccak256(
                    "ClaimMessage(address account,uint256 quantity,uint256 ethValue,uint256 deadline, uint256 chainId)"
                ),
                account,
                quantity,
                ethValue,
                deadline,
                _CHAIN_ID
            )
        );

        return _hashedMessage;
    }

    function _getEthSignedMessageHash(bytes32 _messageHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function _recoverAddress(ClaimMessage memory _message, bytes memory _signature) internal view returns (address) {
        bytes32 hash = _getEthSignedMessageHash(
            getClaimSignatureMessageHash(_message.account, _message.quantity, _message.ethValue, _message.deadline)
        );
        return ECDSA.recover(hash, _signature);
    }

    function withdraw(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success,) = payable(recipient).call{value: address(this).balance}("");
        require(success, "GKoiPresale: Withdraw failed");
    }

    function withdrawUnsoldTokens(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _transferAsset(recipient, _availableTokenIds.length, 0, false);
    }

    function withdrawToken(address _tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        IERC20 token = IERC20(_tokenAddress);
        uint256 _contractBalance = token.balanceOf(address(this));
        (bool status) = token.transfer(msg.sender, _contractBalance);
        require(status, "GKoiPresale: Withdraw failed");
    }
}
