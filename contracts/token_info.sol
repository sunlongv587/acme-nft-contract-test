// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TokenInfo {

    constructor(address _addr, string memory _name, uint256 _amount) public {
        addr = _addr;
        name = _name;
        amount = _amount;
    }

    address public addr;

    string public name;

    uint256 public amount;


    function getAddr() public view returns (address) {
        return addr;
    }

    function getAmount() public view returns (uint256) {
        return amount;
    }

}