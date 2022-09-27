// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../lib/CompareStrings.sol";

contract MarketPlace is ReentrancyGuard {
    using Counters for Counters.Counter;
    using LibExample for string;
    struct EachMarketItem {
        string nftType;
        address nftContract;
        address payable seller;
        address payable owner;
        bool sold;
        uint128 tokenId;
        uint256 createdAt;
        uint256 price;
        uint256 itemId;
    }

    Counters.Counter internal _tokenIds;
    Counters.Counter internal _tokensSold;
    address internal owner;
    uint256 internal listingPrice;
    string[] public nftTypes;
    mapping(uint256 => EachMarketItem) public marketPlaceItems;

    event EachMarketItemMinted(
        string nftType,
        address indexed nftContract,
        address payable seller,
        address payable owner,
        bool sold,
        uint128 indexed tokenId,
        uint256 createdAt,
        uint256 price,
        uint256 indexed itemId
    );

    constructor() {
        owner = msg.sender;
        listingPrice = 0.045 ether;
        nftTypes = ["music", "paint", "sport"];
    }

    modifier onlyOwner() {
        // solhint-disable-next-line
        require(msg.sender == owner, "You are not owner of this contract");
        _;
    }

    function addMarketItem(
        address _nftContract,
        uint128 _tokenId,
        uint256 _price,
        uint8 _nftType
    ) external payable nonReentrant {
        require(_price > 0, "Price must be at least one wei");
        // solhint-disable-next-line
        require(
            msg.value == listingPrice,
            "value must be equal to listing price"
        );

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);
        _tokenIds.increment();
        uint256 currentItemId = _tokenIds.current();
        marketPlaceItems[currentItemId] = EachMarketItem(
            nftTypes[_nftType],
            _nftContract,
            payable(msg.sender),
            payable(address(0)),
            false,
            _tokenId,
            block.timestamp,
            _price,
            currentItemId
        );

        emit EachMarketItemMinted(
            nftTypes[_nftType],
            _nftContract,
            payable(msg.sender),
            payable(address(0)),
            false,
            _tokenId,
            block.timestamp,
            _price,
            currentItemId
        );
    }

    function sellMarketItem(address _nftContract, uint256 _itemId)
        external
        payable
        nonReentrant
    {
        uint256 price = marketPlaceItems[_itemId].price;
        uint256 tokenId = marketPlaceItems[_itemId].tokenId;
        // solhint-disable-next-line
        require(
            msg.value == price,
            "Please submit the asking price in order to continue"
        );
        (bool success, ) = marketPlaceItems[_itemId].seller.call{
            value: msg.value
        }("");
        require(success == true, "failed transfer");
        (bool success1, ) = payable(owner).call{value: listingPrice}("");
        require(success1 == true, "failed transfer2");
        marketPlaceItems[_itemId].sold = true;
        marketPlaceItems[_itemId].owner = payable(msg.sender);
        IERC721(_nftContract).transferFrom(address(this), msg.sender, tokenId);
        _tokensSold.increment();
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function explore(uint256 _index) public view returns (EachMarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = itemCount - _tokensSold.current();
        uint256 currentIndex = 0;
        EachMarketItem[] memory items = new EachMarketItem[](unsoldItemCount);
        for (uint256 i = _index; i < itemCount; i++) {
            if (marketPlaceItems[i].owner == address(0)) {
                uint256 currentId = i;
                EachMarketItem memory currentItem = marketPlaceItems[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    
    function exploreType(uint8 _nftType)
        public
        view
        returns (EachMarketItem[] memory)
    {
        uint256 itemCount = _tokenIds.current();
        uint256 itemCount2 = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            if (marketPlaceItems[i + 1].owner == address(0)) {
                string memory nftType = nftTypes[_nftType];
                bool result = marketPlaceItems[i+1].nftType.compareStrings(nftType);
                if (
                    result == true
                ) {
                    itemCount2 += 1;
                }
            }
        }

        uint256 currentIndex = 0;
        EachMarketItem[] memory items = new EachMarketItem[](itemCount2);
        for (uint256 i = 0; i < itemCount; i++) {
            if (marketPlaceItems[i + 1].owner == address(0)) {
                string memory nftType = nftTypes[_nftType];
                bool result = marketPlaceItems[i+1].nftType.compareStrings(nftType);
                if (
                    result == true
                ) {
                    uint256 currentId = i + 1;
                    EachMarketItem memory currentItem = marketPlaceItems[
                        currentId
                    ];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
        }
        return items;
    }

    function mySellingNFTS() public view returns (EachMarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 itemCount2 = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemCount; i++) {
            if (marketPlaceItems[i + 1].seller == msg.sender) {
                if (marketPlaceItems[i + 1].sold == false) {
                    itemCount2 += 1;
                }
            }
        }

        EachMarketItem[] memory items = new EachMarketItem[](itemCount2);
        for (uint256 i = 0; i < itemCount2; i++) {
            if (marketPlaceItems[i + 1].seller == msg.sender) {
                if (marketPlaceItems[i + 1].sold == false) {
                    uint256 currentId = marketPlaceItems[i + 1].itemId;
                    EachMarketItem memory currentItem = marketPlaceItems[
                        currentId
                    ];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
        }
        return items;
    }

    function addNFTType(string calldata _newType) external onlyOwner {
        nftTypes.push(_newType);
    }

    function updateListingPrice(uint256 _newListinPrice) external onlyOwner {
        listingPrice = _newListinPrice;
    }

    function getNFTsCount() external view onlyOwner returns(uint256) {
        return _tokenIds.current();
    }

    function getSoldNFTsCount() external view onlyOwner returns(uint256) {
        return _tokensSold.current();
    }
    
}
