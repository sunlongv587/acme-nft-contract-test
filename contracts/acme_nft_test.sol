// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./token_info.sol";

contract AcmeNftTest is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint public TYPE_BOX = 1;
    uint public TYPE_SEED = 2;
    uint public TYPE_ACME = 3;

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

    mapping(uint256 => uint) private tokenIdAndTypeMap;

    mapping(uint256 => mapping(address => TokenInfo)) private tokenIdAndInfosMap;

    mapping(uint256 => address[]) private tokenIdAndAddressesMap;

    constructor(string memory initBaseURI, string memory initNotRevealedUri)
    ERC721("Acme NFT Test", "ANT")
    {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    // 铸造 acme 的话，需要传 种子 的 tokenID
    function mintAcme(uint256 tokenId) public {
        require(_exists(tokenId), "Not exists tokenId.");
        // 查询token类型
        uint tokenType = getTokenType(tokenId);
        // 判断 token 类型 是否 seed
        require(tokenType == TYPE_SEED, "Token type must be seed.");
        mapping(address => TokenInfo) storage tokenInfos = getTokenInfos(tokenId);
        // 遍历 seed 中所有的代币合约地址，向铸造用户的账户扣除 amount
        address[] memory contractAddresses = getTokenAddresses(tokenId);
        for (uint i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            // todo tokenInfos[contractAddress] 判空
            // 将用户授权的代币 转账 到 owner 账户
            require(ERC20(contractAddress).transferFrom(msg.sender, owner(), tokenInfos[contractAddress].getAmount()), "Transfer failed.");
            // tokenInfo
        }
        // 使用seed的属性铸造acme
        _mintAcmeMeta(tokenInfos, contractAddresses);
        // buru seed

        // _mintAcmeMeta(tokenQuantity);
    }

    // owner 调用 的 销毁
    function _burnNFT(uint256 tokenId) internal {
        require(_exists(tokenId), "Not exists token id");
        super._burn(tokenId);
        // 判断字符串非空
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        // 删除 type
        delete tokenIdAndTypeMap[tokenId];
        // 删除 合约地址数组
        delete tokenIdAndAddressesMap[tokenId];
        // todo 删除 代币信息map
        // tokenIdAndInfosMap[tokenId] = 0x0;
    }

    function _mintAcmeMeta(mapping(address => TokenInfo) storage tokenInfos, address[] memory addresses) internal {
        uint256 tokenId = totalSupply();
        if (totalSupply() < MAX_SUPPLY) {
            // uri 怎么办？没有提前生成的话，就只能先给个固定的
            setTokenURI(tokenId, baseURI);
            setTokenType(tokenId, TYPE_ACME);
            setTokenInfosByMap(tokenId, tokenInfos, addresses);
            _safeMint(msg.sender, tokenId);
        }

    }

    function setTokenInfosByMap(uint256 tokenId, mapping(address => TokenInfo) storage tokenInfos, address[] memory addresses) internal {
        // address[] memory addresses = new address[](tokenInfos.length);
        for (uint i = 0; i < addresses.length; i++) {
            address contractAddress = addresses[i];
            tokenIdAndInfosMap[tokenId][contractAddress] = tokenInfos[contractAddress];
        }
        // 保存用户的所有地址用来 遍历 map(solidity 的mapping 不支持遍历)
        setTokenAddresses(tokenId, addresses);
    }

    function setTokenInfos(uint256 tokenId, TokenInfo[] memory tokenInfos) internal {
        address[] memory addresses = new address[](tokenInfos.length);
        for (uint i = 0; i < tokenInfos.length; i++) {
            TokenInfo tokenInfo = tokenInfos[i];
            tokenIdAndInfosMap[tokenId][tokenInfo.getAddr()] = tokenInfo;
            addresses[i] = tokenInfo.getAddr();
        }
        // 保存用户的所有地址用来 遍历 map(solidity 的mapping 不支持遍历)
        setTokenAddresses(tokenId, addresses);
    }

    function setTokenAddresses(uint256 tokenId, address[] memory addresses) internal {
        tokenIdAndAddressesMap[tokenId] = addresses;
    }

    function getTokenAddresses(uint256 tokenId) internal view returns (address[] memory) {
        return tokenIdAndAddressesMap[tokenId];
    }

    function getTokenInfos(uint256 tokenId) internal view returns (mapping(address => TokenInfo) storage) {
        // require(tokenIdAndTypeMap[tokenId] != address(0), "Not exists token type");
        return tokenIdAndInfosMap[tokenId];
    }

    function setTokenType(uint256 tokenId, uint tokenType) internal {
        tokenIdAndTypeMap[tokenId] = tokenType;
    }

    function getTokenType(uint256 tokenId) internal view returns (uint) {
        // require(tokenIdAndTypeMap[tokenId] != address(0), "Not exists token type");
        return tokenIdAndTypeMap[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory cid) internal {
        _tokenURIs[tokenId] = cid;
    }

    // owner 调用的铸造方法
    function mintNFT(string memory uri, uint tokenType, TokenInfo[] memory tokenInfos) public onlyOwner {
        uint256 tokenId = totalSupply();
        if (totalSupply() < MAX_SUPPLY) {
            setTokenURI(tokenId, uri);
            setTokenType(tokenId, tokenType);
            setTokenInfos(tokenId, tokenInfos);
            _safeMint(msg.sender, tokenId);
        }
    }

    // owner 调用 的 销毁
    function burnNFT(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Not exists token id");
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        // 删除 type
        delete tokenIdAndTypeMap[tokenId];
        // 删除 合约地址数组
        delete tokenIdAndAddressesMap[tokenId];
        // todo 删除 代币信息map
        // tokenIdAndInfosMap[tokenId] = 0x0;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
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
