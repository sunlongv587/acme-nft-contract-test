// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AcmeNftTest is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public _isSaleActive = true;
    bool public _revealed = false;

    // Constants
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public mintPrice = 0.00003 ether;
    uint256 public maxBalance = 100;
    uint256 public maxMint = 100;

    string baseURI = "ipfs://QmPEK3MiZok3WK8Uas6gKqc6LoVqKCPma1yLkR9y8ZE1pt/";
    string public notRevealedUri = "ipfs://QmUiEffBkwu1846NEem9bvEywdQevShp5ASKCJzZTt9JKs";
    string public baseExtension = ".json";
    string public constant BASE_PREFIX = "ipfs://";

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
    ERC721("Acme NFT Test", "ANT")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    function mintAcmeMeta(uint256 tokenQuantity) public payable {
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        require(_isSaleActive, "Sale must be active to mint AcmeMetas");
        require(
            balanceOf(msg.sender) + tokenQuantity <= maxBalance,
            "Sale would exceed max balance"
        );
        require(
            tokenQuantity * mintPrice <= msg.value,
            "Not enough ether sent"
        );
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");

        _mintAcmeMeta(tokenQuantity);
    }

    function _mintAcmeMeta(uint256 tokenQuantity) internal {
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mintAcmeNft(string account, uint256 tokenQuantity, string cid) onlyOwner {
        uint256 tokenId = totalSupply();
        if (totalSupply() < MAX_SUPPLY) {
            _setTokenURI(tokenId, string(BASE_PREFIX + cid));
            _safeMint(account, tokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        //        if (_revealed == false) {
        //            return notRevealedUri;
        //        }

        string memory _tokenURI = _tokenURIs[tokenId];
        //        string memory base = _baseURI();
        //
        //        // If there is no base URI, return the token URI.
        //        if (bytes(base).length == 0) {
        //            return _tokenURI;
        //        }
        //        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        //        if (bytes(_tokenURI).length > 0) {
        //            return string(abi.encodePacked(base, _tokenURI));
        //        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}
