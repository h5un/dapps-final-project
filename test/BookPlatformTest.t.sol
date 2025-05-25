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

    modifier listOneBook() {
        vm.prank(seller);
        bookSeller.addBook(METADATA_URI, BOOK_PRICE);
        _;
    }

    modifier fundUser() {
        vm.deal(user, 1 ether);
        _;
    }

    modifier userBoughtBook() {
        vm.prank(user);
        bookSeller.buyBook{value: BOOK_PRICE}(0);
        _;
    }

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

    function testPurchaseAndUnlockBookFlow() public listOneBook fundUser userBoughtBook {
        // 驗證使用者是否擁有該書
        bool hasBook = ebookPlatform.hasBook(user, METADATA_URI);
        assertTrue(hasBook, "User should own the book");

        // 使用者支付平台費用解鎖
        vm.prank(user);
        ebookPlatform.payToUnlock{value: PLATFORM_FEE}(0);

        // 驗證是否已解鎖
        bool unlocked = ebookPlatform.isUnlocked(user, 0);
        assertTrue(unlocked, "User should have unlocked access to the book");
    }

    function testRevertIfNotEnoughFee() public listOneBook fundUser userBoughtBook {
        vm.prank(user);
        vm.expectRevert("Insufficient usage fee");
        ebookPlatform.payToUnlock{value: 0.0009 ether}(0);
    }

    function testRevertIfNotOwnerOfNFT() public listOneBook fundUser userBoughtBook {
        // attacker 嘗試解鎖不是自己的書
        address attacker = address(0xCAFE);
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        vm.expectRevert();
        ebookPlatform.payToUnlock{value: PLATFORM_FEE}(0);
    }

    function testPlatformCanWithdraw() public listOneBook fundUser userBoughtBook {
        // User pays platform fee to unlock
        vm.prank(user);
        ebookPlatform.payToUnlock{value: PLATFORM_FEE}(0);

        // Verify platform balance
        uint256 platformBalance = address(ebookPlatform).balance;
        assertEq(platformBalance, PLATFORM_FEE, "Platform balance should equal the fee collected");

        // Platform owner withdraws funds
        vm.prank(platformOwner);
        ebookPlatform.withdraw();

        // Verify platform balance is zero
        platformBalance = address(ebookPlatform).balance;
        assertEq(platformBalance, 0, "Platform balance should be zero after withdrawal");

        // Verify platform owner received the funds
        uint256 ownerBalance = platformOwner.balance;
        assertEq(ownerBalance, PLATFORM_FEE, "Platform owner should receive the withdrawn funds");
    }

    function testOwnerCanSetNewUsageFee() public {
        vm.prank(platformOwner);
        ebookPlatform.setUsageFee(0.02 ether);

        uint256 newFee = ebookPlatform.getUsageFee();
        assertEq(newFee, 0.02 ether);
    }
}
