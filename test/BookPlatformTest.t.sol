// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/BookPlatform.sol";
import "../src/BookNft.sol";
import "../src/BookSeller.sol";

contract BookPlatformTest is Test {
    BookNft public bookNft;
    BookSeller public bookSeller;
    BookPlatform public ebookPlatform;

    address public seller = address(0xABCD);
    address public platformOwner = address(0x5678);
    address public user = address(0x1234);

    string public constant METADATA_URI = "ipfs://QmYNYiPqRt8ojbfFCapn43gwG4wLSY56nHPQWGF6a6XEaH"; // 3Body I
    uint256 public constant BOOK_PRICE = 0.01 ether;
    uint256 public constant PLATFORM_FEE = 0.001 ether;

    function setUp() public {
        // 部署 NFT 合約並設置權限
        vm.startPrank(seller);
        bookNft = new BookNft();
        bookSeller = new BookSeller(address(bookNft));

        bookNft.setMinter(address(bookSeller));
        vm.stopPrank();

        vm.prank(platformOwner);
        ebookPlatform = new BookPlatform(address(bookNft), PLATFORM_FEE);
    }

    function testPurchaseAndUnlockBookFlow() public {
        // 上架一本書
        vm.prank(seller);
        bookSeller.addBook(METADATA_URI, BOOK_PRICE);

        vm.deal(user, 1 ether);

        vm.prank(user);
        bookSeller.buyBook{value: BOOK_PRICE}(0);

        // 驗證 NFT 擁有者
        assertEq(bookNft.ownerOf(0), user);

        // 使用者支付平台費用解鎖
        vm.prank(user);
        ebookPlatform.payToUnlock{value: PLATFORM_FEE}(0);

        // 驗證是否已解鎖
        bool unlocked = ebookPlatform.isUnlocked(user, 0);
        assertTrue(unlocked, "User should have unlocked access to the book");
    }

    function testRevertIfNotEnoughFee() public {
        vm.prank(seller);
        bookSeller.addBook(METADATA_URI, BOOK_PRICE);
        vm.deal(user, 1 ether);
        vm.prank(user);
        bookSeller.buyBook{value: BOOK_PRICE}(0);

        vm.prank(user);
        vm.expectRevert("Insufficient usage fee");
        ebookPlatform.payToUnlock{value: 0.0009 ether}(0);
    }

    function testRevertIfNotOwnerOfNFT() public {
        vm.prank(seller);
        bookSeller.addBook(METADATA_URI, BOOK_PRICE);
        vm.deal(user, 1 ether);
        vm.prank(user);
        bookSeller.buyBook{value: BOOK_PRICE}(0);

        // address 嘗試解鎖不是自己的書
        address attacker = address(0xCAFE);
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        vm.expectRevert();
        ebookPlatform.payToUnlock{value: PLATFORM_FEE}(0);
    }
}
