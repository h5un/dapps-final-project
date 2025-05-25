// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {BookNft} from "./BookNft.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BookSeller is Ownable {
    BookNft public immutable i_bookNft;
    uint256 public s_bookCounter;

    struct Book {
        string metadataUri;
        uint256 price;
        bool exists;
    }

    mapping(uint256 => Book) public s_books;

    constructor(address _bookNft) Ownable(msg.sender){
        i_bookNft = BookNft(_bookNft);
    }

    /// @notice 書商上架書本，每本0.01 ETH
    function addBook(string memory _metadataUri, uint256 _price) external onlyOwner {
        s_books[s_bookCounter] = Book(_metadataUri, _price, true);
        s_bookCounter++;
    }

    /// @notice 用戶購買 NFT 書
    function buyBook(uint256 bookId) external payable {
        Book memory book = s_books[bookId];
        require(book.exists, "Book does not exist");
        require(msg.value >= book.price, "Not enough ETH sent");

        // mint NFT to msg.sender with the book's metadata URI
        i_bookNft.mint(msg.sender, book.metadataUri);

        // 可以考慮退款多餘金額：msg.sender.transfer(msg.value - book.price);
    }

    /// @notice 書商提領收入
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
