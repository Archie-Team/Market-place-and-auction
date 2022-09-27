//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Auction is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public auctionsCount;
    Counters.Counter public soldAuctionsCount;

    struct EachAuction {
        address nftContract;
        address owner;
        uint256 createdAt;
        uint256 tokenId;
        bool ended;
        EachBidder highestBidder;
        mapping(address => bool) users;
        mapping(address => uint256) pastBidders;
    }

    struct AllAuction {
        address nftContract;
        address owner;
        uint256 createdAt;
        uint256 tokenId;
        bool ended;
        EachBidder highestBidder;
    }

    struct EachBidder {
        address payable bidderAddress;
        uint256 bidderAmount;
    }

    address payable public owner;
    uint256 public listingPrice;
    mapping(uint256 => EachAuction) public auctions;

    event AuctionCreated(
        address nftContract,
        uint256 createdAt,
        uint256 tokenId,
        bool ended,
        EachBidder lastBidder
    );


    modifier onlyOwner() {
        require(msg.sender == owner , "You are not the owner");
        _;
    }
    constructor() {
        owner = payable(msg.sender);
        listingPrice = 0.045 ether;
    }

    modifier isEnded(uint256 _auctionId) {
        EachAuction storage theAuction = auctions[_auctionId];
        if (theAuction.createdAt < block.timestamp) {
            theAuction.ended = true;
            soldAuctionsCount.increment();
            revert("auction has been ended");
        }
        _;
    }

    modifier ended(uint256 _auctionId) {
        EachAuction storage theAuction = auctions[_auctionId];
        require(theAuction.ended == true, "Aucton is still open");
        _;
    }

    function addAuctionItem(
        address _nftContract,
        uint256 _tokenId,
        uint256 _startingBid,
        uint256 _duration
    ) external payable nonReentrant {
        require(_startingBid > 0, "Starting bid must be at least one wei!");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price!"
        );
        require(_duration > 0, "Duration can not be zero!");

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        auctionsCount.increment();
        uint256 currentId = auctionsCount.current();
        uint256 duration = block.timestamp + _duration;

        EachAuction storage theAuction = auctions[currentId];
        theAuction.nftContract = _nftContract;
        theAuction.owner = msg.sender;
        theAuction.tokenId = _tokenId;
        theAuction.createdAt = _duration;

        EachBidder memory highestBidder = EachBidder(
            payable(msg.sender),
            _startingBid
        );

        theAuction.highestBidder = highestBidder;
        theAuction.users[msg.sender] = true;

        emit AuctionCreated(
            _nftContract,
            duration,
            _tokenId,
            false,
            highestBidder
        );
    }

    function bid(uint256 _auctionId, uint256 _newBid)
        external
        payable
        nonReentrant
        isEnded(_auctionId)
    {
        uint256 highestBidderAmount = auctions[_auctionId]
            .highestBidder
            .bidderAmount;
        address highestBidderAddress = auctions[_auctionId]
            .highestBidder
            .bidderAddress;

        require(
            _newBid > highestBidderAmount,
            "Your bid is lower than the lastest bidder"
        );

        (bool success, ) = address(this).call{value: msg.value}("");
        require(success == true, "Transfered failed");

        EachAuction storage theAuction = auctions[_auctionId];
        if (msg.sender == theAuction.owner) {
            theAuction.pastBidders[highestBidderAddress] = 0;
        } else {
            theAuction.pastBidders[highestBidderAddress] = highestBidderAmount;
        }

        uint256 newBidAmount = theAuction.pastBidders[msg.sender] + _newBid;
        auctions[_auctionId].highestBidder.bidderAddress = payable(msg.sender);
        auctions[_auctionId].highestBidder.bidderAmount = newBidAmount;
    }

    function winOfAuction(uint256 _auctionId)
        external
        payable
        nonReentrant
        ended(_auctionId)
    {
        EachAuction storage theAuction = auctions[_auctionId];

        address highestBidderAddress = theAuction.highestBidder.bidderAddress;
        require(
            msg.sender == highestBidderAddress,
            "You are not the highestBidder"
        );

        uint256 highestBidderAmount = theAuction.highestBidder.bidderAmount;
        address nftOwner = auctions[_auctionId].owner;
        address nftContract = theAuction.nftContract;
        uint256 tokenId = theAuction.tokenId;

        (bool success, ) = nftOwner.call{value: highestBidderAmount}("");
        require(success == true, "Transfered failed");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawOfAuction(uint256 _auctionId)
        external
        payable
        nonReentrant
        ended(_auctionId)
    {
        EachAuction storage theAuction = auctions[_auctionId];
        require(msg.sender != theAuction.owner, "You can't!!!!!");
        uint256 amount = theAuction.pastBidders[msg.sender];
        theAuction.pastBidders[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success == true, "Transfered failed");
    }

    function getAuctions(uint256 _index)
        external
        view
        returns (AllAuction[] memory)
    {
        uint256 itemCount = auctionsCount.current();
        uint256 unsoldItemCount = itemCount - soldAuctionsCount.current();
        uint256 currentIndex = 0;
        AllAuction[] memory items = new AllAuction[](unsoldItemCount);
        for (uint256 i = _index; i < itemCount; i++) {
            uint256 currentId = i;
            EachAuction storage currentAuction = auctions[currentId];

            EachBidder memory highestBidder = EachBidder(
                currentAuction.highestBidder.bidderAddress,
                currentAuction.highestBidder.bidderAmount
            );
            AllAuction memory theAuction = AllAuction(
                currentAuction.nftContract,
                currentAuction.owner,
                currentAuction.createdAt,
                currentAuction.tokenId,
                currentAuction.ended,
                highestBidder
            );

            items[currentIndex] = theAuction;
            currentIndex += 1;
        }
        return items;
    }

    function getAuction(uint256 _auctionId)
        external
        view
        returns (AllAuction memory)
    {
        EachAuction storage currentAuction = auctions[_auctionId];

        EachBidder memory highestBidder = EachBidder(
            currentAuction.highestBidder.bidderAddress,
            currentAuction.highestBidder.bidderAmount
        );

        AllAuction memory theAuction = AllAuction(
            currentAuction.nftContract,
            currentAuction.owner,
            currentAuction.createdAt,
            currentAuction.tokenId,
            currentAuction.ended,
            highestBidder
        );
        return theAuction;
    }

    function updateListingPrice(uint256 _listingPrice) external onlyOwner {
        listingPrice = _listingPrice;
    }

}
