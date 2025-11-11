// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {OwnableBasic} from "@limitbreak/creator-token-standards/src/access/OwnableBasic.sol";
import {ERC721AC} from "@limitbreak/creator-token-standards/src/erc721c/ERC721AC.sol";
import {
    BasicRoyalties,
    BasicRoyaltiesBase
} from "@limitbreak/creator-token-standards/src/programmable-royalties/BasicRoyalties.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

contract GKoiBattleCards is OwnableBasic, ERC721AC, ERC2981, BasicRoyalties {
    string private _contractUri;
    string private _baseUri;
    uint256 public constant MAX_SUPPLY = 10_000;

    modifier checkMaxSupply(uint256 quantity) {
        _checkMaxSupply(quantity);
        _;
    }

    constructor(
        address royaltyReceiver_,
        uint96 royaltyFeeNumerator_,
        string memory name_,
        string memory symbol_,
        string memory _contractUri_
    ) ERC721AC(name_, symbol_) BasicRoyalties(royaltyReceiver_, royaltyFeeNumerator_) {
        _contractUri = _contractUri_;
    }

    function _checkMaxSupply(uint256 quantity) internal view {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AC, ERC2981) returns (bool) {
        return ERC721AC.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 quantity) external onlyOwner checkMaxSupply(quantity) {
        _mint(to, quantity);
    }

    function safeMint(address to, uint256 quantity) external onlyOwner checkMaxSupply(quantity) {
        _safeMint(to, quantity);
    }

    // function burn(uint256 tokenId) external onlyOwner() {
    //     _burn(tokenId);
    // }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal override(BasicRoyaltiesBase, ERC2981) {
        _requireCallerIsContractOwner();
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        internal
        override(BasicRoyaltiesBase, ERC2981)
    {
        _requireCallerIsContractOwner();
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
}
