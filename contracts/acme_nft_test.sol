// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AcmeNftTest is ERC721Enumerable, Ownable {

    struct TokenInfo {

        address addr;

        string name;

        uint256 amount;
    }
    using Strings for uint256;

    uint public TYPE_BOX = 1;
    uint public TYPE_SEED = 2;
    uint public TYPE_ACME = 3;

    // Constants
    uint256 public constant MAX_SUPPLY = 100000;

    string baseURI = "ipfs://QmPEK3MiZok3WK8Uas6gKqc6LoVqKCPma1yLkR9y8ZE1pt/";
    uint256 public totalBurned = 0;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => uint) private tokenIdAndTypeMap;

    mapping(uint256 => mapping(address => TokenInfo)) private tokenIdAndInfosMap;

    mapping(uint256 => address[]) private tokenIdAndAddressesMap;

    mapping(address => uint256[]) private addressAndTokenIds;

    constructor(string memory initBaseURI)
    ERC721("Acme NFT Test02", "ANT")
    {
        setBaseURI(initBaseURI);
    }

    function tokenIdsOf(address addr) public view returns (uint256[] memory) {
        return addressAndTokenIds[addr];
        // return tokenIdAndInfosMap[tokenId][addr];
    }

    // 铸造 acme 的话，需要传 种子 的 tokenID
    function mintAcme(uint256 tokenId) public {
        require(_exists(tokenId), "Not exists tokenId.");
        // 查询token类型
        uint tokenType = _getTokenType(tokenId);
        // 判断 token 类型 是否 seed
        require(tokenType == TYPE_SEED, "Token type must be seed.");
        mapping(address => TokenInfo) storage tokenInfos = _getTokenInfos(tokenId);
        // 遍历 seed 中所有的代币合约地址，向铸造用户的账户扣除 amount
        address[] memory contractAddresses = _getTokenAddresses(tokenId);
        for (uint i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            // todo tokenInfos[contractAddress] 判空
            // 将用户授权的代币 转账 到 合约 账户
            require(ERC20(contractAddress).transferFrom(msg.sender, address(this), tokenInfos[contractAddress].amount), "Transfer failed.");
        }
        // 使用seed的属性铸造acme
        _mintAcmeMeta(tokenInfos, contractAddresses);
        // buru seed
        _burnNFT(tokenId);
        // _mintAcmeMeta(tokenQuantity);
        // 已销毁计数
        totalBurned++;
        // 从地址的持有列表中删除
        // addressAndTokenIds
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
        uint256 tokenId = totalSupply() + totalBurned;
        if (totalSupply() < MAX_SUPPLY) {
            // uri 怎么办？没有提前生成的话，就只能先给个固定的
            setTokenURI(tokenId, baseURI);
            setTokenType(tokenId, TYPE_ACME);
            setTokenInfosByMap(tokenId, tokenInfos, addresses);
            _setAddressAndTokenId(msg.sender, tokenId);
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


    function _setAddressAndTokenId(address addr,uint256 tokenId) internal {
        if(addressAndTokenIds[addr].length == 0) {
            uint256[] memory tokenIds = new uint256[](1);
            tokenIds[0] = tokenId;
            addressAndTokenIds[addr] = tokenIds;
        } else {
            uint256[] memory tokenIds = new uint256[](addressAndTokenIds[addr].length + 1);
            for(uint i = 0; i < addressAndTokenIds[addr].length; i++){
                tokenIds[i] = addressAndTokenIds[addr][i];
            }
            tokenIds[addressAndTokenIds[addr].length] = tokenId;
            addressAndTokenIds[addr] = tokenIds;
        }
    }

    function setTokenInfos(uint256 tokenId, TokenInfo[] memory tokenInfos) internal {
        address[] memory addresses = new address[](tokenInfos.length);
        for (uint i = 0; i < tokenInfos.length; i++) {
            TokenInfo memory tokenInfo = tokenInfos[i];
            tokenIdAndInfosMap[tokenId][tokenInfo.addr] = tokenInfo;
            addresses[i] = tokenInfo.addr;
        }
        // 保存用户的所有地址用来 遍历 map(solidity 的mapping 不支持遍历)
        setTokenAddresses(tokenId, addresses);
    }

    function setTokenAddresses(uint256 tokenId, address[] memory addresses) internal {
        tokenIdAndAddressesMap[tokenId] = addresses;
    }

    function _getTokenAddresses(uint256 tokenId) internal view returns (address[] memory) {
        return tokenIdAndAddressesMap[tokenId];
    }

    function _getTokenInfos(uint256 tokenId) internal view returns (mapping(address => TokenInfo) storage) {
        // require(tokenIdAndTypeMap[tokenId] != address(0), "Not exists token type");
        return tokenIdAndInfosMap[tokenId];
    }

    function setTokenType(uint256 tokenId, uint tokenType) internal {
        tokenIdAndTypeMap[tokenId] = tokenType;
    }

    function _getTokenType(uint256 tokenId) internal view returns (uint) {
        // require(tokenIdAndTypeMap[tokenId] != address(0), "Not exists token type");
        return tokenIdAndTypeMap[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory cid) internal {
        _tokenURIs[tokenId] = cid;
    }

    // owner 调用的铸造方法
    function _mintNFT(string memory uri, uint tokenType, TokenInfo[] memory tokenInfos) internal {
        uint256 tokenId = totalSupply() + totalBurned;
        if (totalSupply() < MAX_SUPPLY) {
            setTokenURI(tokenId, uri);
            setTokenType(tokenId, tokenType);
            setTokenInfos(tokenId, tokenInfos);
            _setAddressAndTokenId(msg.sender, tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    // owner 调用的铸造方法
    function _mintNFT(address to, string memory uri, uint tokenType, TokenInfo[] memory tokenInfos) internal {
        uint256 tokenId = totalSupply() + totalBurned;
        if (totalSupply() < MAX_SUPPLY) {
            setTokenURI(tokenId, uri);
            setTokenType(tokenId, tokenType);
            setTokenInfos(tokenId, tokenInfos);
            _setAddressAndTokenId(to, tokenId);
            _mint(to, tokenId);
        }
    }

    // owner 调用的铸造方法
    function _mintNFT(address to, uint256 tokenId, string memory uri, uint tokenType, TokenInfo[] memory tokenInfos) internal {
        require(!_exists(tokenId), "Already exists tokenId.");
        if (totalSupply() < MAX_SUPPLY) {
            setTokenURI(tokenId, uri);
            setTokenType(tokenId, tokenType);
            setTokenInfos(tokenId, tokenInfos);
            _setAddressAndTokenId(to, tokenId);
            _mint(to, tokenId);
        }
    }


    // owner 调用的铸造方法
    function mintNFT(string memory uri, uint tokenType, address[] memory addresses, string[] memory names, uint256[] memory amounts) public onlyOwner {
        TokenInfo[] memory tokenInfos = new TokenInfo[](addresses.length);
        for (uint i = 0;i < addresses.length; i++) {
            tokenInfos[i] = TokenInfo(addresses[i], names[i], amounts[i]);
        }
        _mintNFT(uri, tokenType, tokenInfos);
    }


    // owner 调用的铸造方法
    function mintNFTById(address to, string memory uri, uint tokenType, address[] memory addresses, string[] memory names, uint256[] memory amounts) public onlyOwner {
        TokenInfo[] memory tokenInfos = new TokenInfo[](addresses.length);
        for (uint i = 0;i < addresses.length; i++) {
            tokenInfos[i] = TokenInfo(addresses[i], names[i], amounts[i]);
        }
        _mintNFT(to, uri, tokenType, tokenInfos);
    }

    // owner 调用的铸造方法
    function mintNFTById(address to, uint256 tokenId, string memory uri, uint tokenType, address[] memory addresses, string[] memory names, uint256[] memory amounts) public onlyOwner {
        TokenInfo[] memory tokenInfos = new TokenInfo[](addresses.length);
        for (uint i = 0;i < addresses.length; i++) {
            tokenInfos[i] = TokenInfo(addresses[i], names[i], amounts[i]);
        }
        _mintNFT(to, tokenId, uri, tokenType, tokenInfos);
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
        // 已销毁计数
        totalBurned++;
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function getTokenType(uint256 tokenId) public onlyOwner view returns (uint) {
        return tokenIdAndTypeMap[tokenId];
    }

    function getTokenAddresses(uint256 tokenId) public onlyOwner view returns (address[] memory) {
        return tokenIdAndAddressesMap[tokenId];
    }

    function getTokenInfo(uint256 tokenId, address addr) public onlyOwner view returns (TokenInfo memory) {
        return tokenIdAndInfosMap[tokenId][addr];
    }

}
