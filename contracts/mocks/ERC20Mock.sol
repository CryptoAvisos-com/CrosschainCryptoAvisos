//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {

    constructor (string memory name, string memory symbol) ERC20(name, symbol) payable {
        _mint(msg.sender, 21000000 ether);
    }

    function mint(address _to, uint qty) public {
        _mint(_to, qty);
    }

    receive() external payable {

    }

}