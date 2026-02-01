//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OurToken is ERC20{
    //minting -> creating tokens
    constructor(uint256 initialSupply) ERC20("OurToken","OTk"){
        _mint(msg.sender,initialSupply);
    }
}