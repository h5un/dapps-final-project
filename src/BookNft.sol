// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BookNft is ERC721, Ownable {
    uint256 public s_tokenCounter;
    address private s_minter;
    mapping(uint256 => string) private s_tokenIdToUri;

    modifier onlyMinter() {
        require(msg.sender == s_minter, "Not authorized to mint");
        _;
    }

    constructor() ERC721("3Body", "3B") Ownable(msg.sender) {
        s_tokenCounter = 0;
    }

    function setMinter(address _minter) external onlyOwner {
        s_minter = _minter;
    }

    function mint(address _to, string memory _tokenUri) external onlyMinter {
        _safeMint(_to, s_tokenCounter);
        s_tokenIdToUri[s_tokenCounter] = _tokenUri;
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return s_tokenIdToUri[tokenId];
    }
}