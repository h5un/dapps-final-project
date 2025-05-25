// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/BookNft.sol";
import "../src/BookSeller.sol";

contract BookSellerTest is Test {
    BookNft public bookNft;
    BookSeller public bookSeller;

    // address owner = vm.addr(uint256(vm.envUint("PRIVATE_KEY"))); // 書商（部署合約）
    address owner = address(0xABCD); // 模擬書商（EOA）
    address buyer = address(0x1234); // 模擬使用者（EOA）

    string book1 = "ipfs://QmYNYiPqRt8ojbfFCapn43gwG4wLSY56nHPQWGF6a6XEaH"; // 3body I
    string book2 = "ipfs://QmUwdf1Wfcw9k95E9E3fctepJp1YxZ1K4WQ9BU6dccLc77"; // 3body II
    string book3 = "ipfs://QmTeTcRwyqW5V6bwgge8i5gEjmWYAdmZmNZqwzXyhvjg5L"; // 3body III

    function setUp() public {
        vm.startPrank(owner);
        bookNft = new BookNft();
        bookSeller = new BookSeller(address(bookNft));

        bookNft.setMinter(address(bookSeller)); // 設定 BookNft 的 mint 權限給書商

        bookSeller.addBook(book1, 0.01 ether);
        bookSeller.addBook(book2, 0.01 ether);
        bookSeller.addBook(book3, 0.01 ether);
        vm.stopPrank();
    }

    function testBuyerCanPurchaseBookAndMintNft() public {
        vm.deal(buyer, 1 ether); // 給 buyer 一些 ETH

        vm.prank(buyer);
        bookSeller.buyBook{value: 0.01 ether}(0); // 購買第 0 本書

        // 檢查 buyer 是否拿到 tokenId = 0 的 NFT
        assertEq(bookNft.ownerOf(0), buyer);

        // 檢查 tokenURI 是否正確
        string memory uri = bookNft.tokenURI(0);
        assertEq(uri, book1);

        // 檢查 buyer 是否擁有該書籍
        bool hasBook = bookNft.getHasBookByUri(buyer, book1);
        assertTrue(hasBook);
    }

    function testBuyBookFailsIfNotEnoughEth() public {
        vm.deal(buyer, 0.005 ether);

        vm.prank(buyer);
        vm.expectRevert("Not enough ETH sent");
        bookSeller.buyBook{value: 0.005 ether}(0);
    }

    function testWithdrawBalanceToOwner() public {
        vm.deal(buyer, 1 ether);
        vm.prank(buyer);
        bookSeller.buyBook{value: 0.01 ether}(0);

        uint256 before = owner.balance;

        vm.prank(owner);
        bookSeller.withdraw();

        uint256 afterBalance = owner.balance;
        assertEq(afterBalance, before + 0.01 ether);
    }
}
