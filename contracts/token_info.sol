// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TokenInfo {

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