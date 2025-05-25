# Web3 Ebook Smart Contracts

This project defines a set of smart contracts for a decentralized eBook platform, where users purchase books as NFTs and can unlock reading access by paying a platform usage fee.

## Overview

The system consists of three contracts:

### BookNft.sol
An ERC-721 NFT contract representing book ownership.

- Each NFT represents a specific book.
- The `tokenURI` stores the IPFS metadata URI of the book.
- Only the authorized `BookSeller` contract can mint new NFTs.

### BookSeller.sol
A contract that allows the book publisher to list and sell books.

- The owner can add books with a metadata URI and price.
- Users can purchase books, which mints a new NFT with the given metadata.
- Each purchase generates a unique `tokenId`, but metadata can be shared across users.

### BookPlatform.sol
A contract that allows NFT holders to pay a usage fee to unlock reading access.

- Users who own a book NFT can call `payToUnlock(tokenId)` and send ETH to unlock usage rights.
- The contract tracks which users have unlocked which tokens.
- Also provides `ownsBookByMetadata(address, metadataURI)` for checking ownership by content identity.

## Usage Flow

1. The publisher uploads book content to IPFS and creates a metadata JSON.
2. The metadata URI is registered on `BookSeller` via `addBook`.
3. A user buys the book by calling `buyBook(bookId)` and receives an NFT.
4. The user then calls `payToUnlock(tokenId)` on `BookPlatform` to enable access.
5. The contract tracks access permissions per user and tokenId.

## Deployment Order

1. Deploy `BookNft.sol`
2. Deploy `BookSeller.sol` with the NFT contract address
3. Call `setMinter(bookSellerAddress)` on `BookNft`
4. Deploy `BookPlatform.sol` with the NFT contract address and usage fee

## License

MIT
