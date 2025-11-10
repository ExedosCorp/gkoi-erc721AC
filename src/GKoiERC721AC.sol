// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ERC721AC} from  "@limitbreak/creator-token-standards/src/erc721c/ERC721AC.sol";


import {OwnableBasic} from "@limitbreak/creator-token-standards/src/access/OwnableBasic.sol";
import {ERC721AC} from "@limitbreak/creator-token-standards/src/erc721c/ERC721AC.sol";
import {BasicRoyalties, BasicRoyaltiesBase} from "@limitbreak/creator-token-standards/src/programmable-royalties/BasicRoyalties.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GKoiERC721AC is OwnableBasic, ERC721AC, ERC2981, BasicRoyalties {
    constructor(
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        string memory name_,
        string memory symbol_) 
        ERC721AC(name_, symbol_) 
        BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_) {
    }

    function contractURI() public view returns (string memory) {
        return "https://external-link-url.com/my-contract-metadata.json";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, ERC2981) returns (bool) {
        return ERC721AC.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function safeMint(address to, uint256 quantity) external {
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal override(BasicRoyaltiesBase, ERC2981) {
        _requireCallerIsContractOwner();
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal override(BasicRoyaltiesBase, ERC2981) {
        _requireCallerIsContractOwner();
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
}
