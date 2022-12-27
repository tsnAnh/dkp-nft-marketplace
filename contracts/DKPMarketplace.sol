// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract DKPMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;

    address payable owner;

    uint256 listingPrice = 0.045 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketToken {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        string category;
        uint256 dateMinted;
    }

    mapping(uint256 => MarketToken) private idToMarketToken;

    event MarketTokenMinted(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        string category,
        uint256 dateMinted
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function makeMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        string memory category
    ) public payable nonReentrant {
        require(price > 0, "Price must be at least one wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        _tokenIds.increment();
        uint256 itemId = _tokenIds.current();

        idToMarketToken[itemId] = MarketToken(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            category,
            block.timestamp
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false,
            category,
            block.timestamp
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
    public
    payable
    nonReentrant
    {
        uint256 price = idToMarketToken[itemId].price;
        uint256 tokenId = idToMarketToken[itemId].tokenId;

        require(
            msg.value == price,
            "Please submit the asking price in order to continue"
        );

        // transfer amount
        idToMarketToken[itemId].seller.transfer(msg.value);
        // transfer token
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idToMarketToken[itemId].owner = payable(msg.sender);
        idToMarketToken[itemId].sold = true;
        _tokensSold.increment();

        payable(owner).transfer(listingPrice);
    }

    function fetchMarketTokens() public view returns (MarketToken[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = itemCount - _tokensSold.current();
        uint256 currentIndex = 0;

        MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketToken[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }

        return items;
    }

    function fetchMyNFTs() public view returns (MarketToken[] memory) {
        uint totalItemCount = _tokenIds.current();

        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].owner == msg.sender) {
                uint currentId = idToMarketToken[i + 1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function fetchItemsCreated() public view returns (MarketToken[] memory) {
        uint totalItemCount = _tokenIds.current();

        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].seller == msg.sender) {
                uint currentId = idToMarketToken[i + 1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }
}
