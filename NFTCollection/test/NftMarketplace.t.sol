// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import 'forge-std/Test.sol';
import '../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import '../src/NftMarketplace.sol';

contract MockMFT is ERC721{

    constructor() ERC721("MockNft", "MNFT") {}

    function mint(address to, uint256 tokenId) external{
        _mint(to, tokenId);
    }
}

contract NftMarketplaceTest is Test{

    NftMarketplace marketplace;
    MockMFT nft;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;

    function setUp() public {
        vm.startPrank(deployer);
        marketplace = new NftMarketplace();
        nft = new MockMFT();
        vm.stopPrank();

        vm.startPrank(user);
        nft.mint(user, tokenId);
        vm.stopPrank();
    }

    function testOwneroOf() public {
        address ownerOf = nft.ownerOf(tokenId);
        assert(ownerOf == user);
    }

    function testShuldRevertIfPriceIsZero() public {
        vm.startPrank(user);

        vm.expectRevert("Price can not be 0");
        marketplace.listNft(address(nft), tokenId, 0);

        vm.stopPrank();
    }

    function testShuldRevertIfSerderisNotOwner() public {
        vm.startPrank(user);

        uint256 tokenId2_ = 1;
        address user2_ = vm.addr(3);
        nft.mint(user2_, tokenId2_);

        vm.expectRevert("Sender is not Owner of NFT");
        marketplace.listNft(address(nft), tokenId2_, 1);

        vm.stopPrank();
    }

    function testListNftCorrecty() public {
        vm.startPrank(user);

        (address sellerBefore, address nftAddresBefore, uint256 tokenIdBefore, uint256 priceBefore) = marketplace.listing(address(nft), tokenId);

        marketplace.listNft(address(nft), tokenId, 1);

        (address sellerAfter, address nftAddresAfter, uint256 tokenIdAfter, uint256 priceAfter) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore != sellerAfter);

        vm.stopPrank();
    }

    function testCancelListNftShuldBeReverByNotListingOwner() public {

        vm.startPrank(user);
        (address sellerBefore, address nftAddresBefore, uint256 tokenIdBefore, uint256 priceBefore) = marketplace.listing(address(nft), tokenId);
        marketplace.listNft(address(nft), tokenId, 1);
        (address sellerAfter, address nftAddresAfter, uint256 tokenIdAfter, uint256 priceAfter) = marketplace.listing(address(nft), tokenId);
        assert(sellerBefore != sellerAfter);
        vm.stopPrank();

        address user2_ = vm.addr(3);

        vm.startPrank(user2_);
        vm.expectRevert("You not the Listing Owner");
        marketplace.cancelList(address(nft), tokenId);
        vm.stopPrank();
    }

    function testCancelListCorrectly() public {

        vm.startPrank(user);
        (address sellerBefore, address nftAddresBefore, uint256 tokenIdBefore, uint256 priceBefore) = marketplace.listing(address(nft), tokenId);
        marketplace.listNft(address(nft), tokenId, 1);
        (address sellerAfter, address nftAddresAfter, uint256 tokenIdAfter, uint256 priceAfter) = marketplace.listing(address(nft), tokenId);
        assert(sellerBefore != sellerAfter);

        marketplace.cancelList(address(nft), tokenId);
        (address sellerAfterCancel, , ,) = marketplace.listing(address(nft), tokenId);
        assert(sellerAfterCancel == address(0));
        vm.stopPrank();
    }

    function testBuyNftShuldBeRevertListingNotExist() public {

        vm.startPrank(user);
        uint256 tokenIdNotExist = 10;

        vm.expectRevert("Listing not exists");
        marketplace.buyNft(address(nft), tokenIdNotExist);

        vm.stopPrank();
    }

    function testBuyNftShuldBeRevertIncorrectPrice() public {
        uint256 price = 10;
        vm.startPrank(user);

        (address sellerBefore, address nftAddresBefore, uint256 tokenIdBefore, uint256 priceBefore) = marketplace.listing(address(nft), tokenId);
        marketplace.listNft(address(nft), tokenId, price);
        (address sellerAfter, address nftAddresAfter, uint256 tokenIdAfter, uint256 priceAfter) = marketplace.listing(address(nft), tokenId);
        assert(sellerBefore != sellerAfter);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price);

        vm.expectRevert("Incorrect price");
        marketplace.buyNft{value: price -1}(address(nft), tokenId);
        vm.stopPrank();
    }

    function testBuyNftCorrectly() public {
        uint256 price = 10;
        vm.startPrank(user);

        (address sellerBefore, address nftAddresBefore, uint256 tokenIdBefore, uint256 priceBefore) = marketplace.listing(address(nft), tokenId);
        marketplace.listNft(address(nft), tokenId, price);
        (address sellerAfter, address nftAddresAfter, uint256 tokenIdAfter, uint256 priceAfter) = marketplace.listing(address(nft), tokenId);
        
        assert(sellerBefore != sellerAfter);
        nft.approve(address(marketplace), tokenId);

        vm.stopPrank();

        address user2_ = vm.addr(3);
        vm.startPrank(user2_);
        vm.deal(user2_, price);

        uint256 balanceBeforeBuy = address(user).balance;
        address ownerOfBeforeBuy = nft.ownerOf(tokenId);
        (address sellerBeforeBuy,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.buyNft{value: price}(address(nft), tokenId);
        (address sellerAfterBuy,,,) = marketplace.listing(address(nft), tokenId);
        address ownerOfAfterBuy = nft.ownerOf(tokenId);
        uint256 balanceAfteBuy = address(user).balance;


        assert(sellerBeforeBuy == user && sellerAfterBuy == address(0));
        assert(ownerOfBeforeBuy == user && ownerOfAfterBuy == user2_);
        assert(balanceBeforeBuy == balanceAfteBuy - price);
        vm.stopPrank();
    }
}

