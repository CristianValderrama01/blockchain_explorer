// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import {Strings} from '../lib/openzeppelin-contracts/contracts/utils/Strings.sol';

contract NFTCollection is ERC721 {

    using Strings for uint256;

    uint256 public currentTokenId;
    uint256 public totalSupply;
    string public baseUri;

    event MintNFT(address to, uint256 tokenId);

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, string memory baseUri_) ERC721(name_, symbol_) {
        totalSupply = totalSupply_;
        baseUri = baseUri_;
    }

    function mint() external {

        require(currentTokenId < totalSupply, "Sold out");
        _safeMint(msg.sender, currentTokenId);
        currentTokenId++;

        emit MintNFT(msg.sender, currentTokenId--);
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId) public override view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString(), ".json") : "";
    }

}