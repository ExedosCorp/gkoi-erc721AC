// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ERC721C} from  "@limitbreak/creator-token-standards/src/erc721c/ERC721C.sol";

// contract GKoiERC721C is ERC721C, Ownable {

//     // string private _baseTokenURI;

//     constructor(string memory name, string memory symbol) ERC721C(name, symbol) Ownable(msg.sender) {
//         initializeERC721(name, symbol);
//     }

//     // function setBaseURI(string memory baseURI) external onlyOwner {
//     //     _baseTokenURI = baseURI;
//     // }

//     // function _baseURI() internal view override returns (string memory) {
//     //     return _baseTokenURI;
//     // }

//     function mint(address to, uint256 tokenId) external onlyOwner {
//         _mint(to, tokenId);
//     }

//     function _requireCallerIsContractOwner() internal view override {
//         require(owner() == _msgSender(), "Caller is not the contract owner");
//     }
// }
