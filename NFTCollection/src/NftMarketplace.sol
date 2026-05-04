// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import '../lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import '../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol';

contract NftMarketplace is Ownable, ReentrancyGuard{

    struct Listing {
        address seller;
        address nftAddres;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listing;

    event NftListed(address indexed seller, address indexed nftAddres, uint256 indexed tokenId, uint256 price);
    event NftCancel(address indexed seller, address indexed nftAddres, uint256 indexed tokenId);
    event NftSold(address indexed buyer, address indexed seller, address indexed nftAddres, uint256 tokenId, uint256 price);

    constructor() Ownable(msg.sender) {
    }

    function listNft(address nftAddres_, uint256 tokenId_, uint256 price_) external {

        require(price_ > 0, "Price can not be 0");
        address owner_ = ERC721(nftAddres_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "Sender is not Owner of NFT");

        Listing memory listing_ = Listing({
            seller: msg.sender,
            nftAddres: nftAddres_,
            tokenId: tokenId_,
            price: price_
        });

        listing[nftAddres_][tokenId_] = listing_;

        emit NftListed(msg.sender, nftAddres_, tokenId_, price_);
    }

    function cancelList(address nftAddres_, uint256 tokenId_) external {

        Listing memory listing_ = listing[nftAddres_][tokenId_];

        require(listing_.seller == msg.sender, "You not the Listing Owner");
        delete listing[nftAddres_][tokenId_];

        emit NftCancel(msg.sender, nftAddres_, tokenId_);
    }

    function buyNft(address nftAddres_, uint256 tokenId_) external payable nonReentrant{
        Listing memory listing_ = listing[nftAddres_][tokenId_];
        require(listing_.price > 0, "Listing not exists");
        require(listing_.price == msg.value, "Incorrect price");

        delete listing[nftAddres_][tokenId_];

        emit NftCancel(msg.sender, nftAddres_, tokenId_);

        ERC721(nftAddres_).safeTransferFrom(listing_.seller, msg.sender, tokenId_);

        (bool success, ) = listing_.seller.call{value: listing_.price}("");
        require(success, "Fail");

        emit NftSold(listing_.seller, msg.sender, nftAddres_, tokenId_, listing_.price);
    }

}