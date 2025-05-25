// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {BookNft} from "./BookNft.sol";
import {BookSeller} from "./BookSeller.sol";

/**
 * BookPlatform 合約 - 驗證用戶擁有 NFT 並支付平台費用後解鎖書籍
 */
contract BookPlatform is Ownable {
    BookNft public bookNft;
    uint256 public usageFee; // 每次使用書籍的費用

    // user => tokenId => paid?
    mapping(address => mapping(uint256 => bool)) public hasPaid;

    constructor(address _bookNft, uint256 _usageFee) Ownable(msg.sender) {
        bookNft = BookNft(_bookNft);
        usageFee = _usageFee;
    }

    function payToUnlock(uint256 tokenId) external payable {
        require(bookNft.ownerOf(tokenId) == msg.sender, "You don't own this book");
        require(msg.value >= usageFee, "Insufficient usage fee");

        hasPaid[msg.sender][tokenId] = true;
    }

    function isUnlocked(address user, uint256 tokenId) external view returns (bool) {
        return hasPaid[user][tokenId];
    }

    function setUsageFee(uint256 _newFee) external onlyOwner {
        usageFee = _newFee;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
