//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MintNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address internal marketPlaceAddress;
    address internal auctionAddress;

    constructor(address _marketPlaceAddress , address _auctionAddress) ERC721("VOMMIO", "VMM") {
        marketPlaceAddress = _marketPlaceAddress;
        auctionAddress = _auctionAddress;
    }

    function mintNFT(string memory _tokenURI) public  returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender , newItemId);
        _setTokenURI(newItemId , _tokenURI);
        setApprovalForAll(marketPlaceAddress , true);
        setApprovalForAll(auctionAddress , true);
        return newItemId;
    }
}
