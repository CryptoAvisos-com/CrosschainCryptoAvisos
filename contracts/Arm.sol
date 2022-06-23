// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./abstracts/arm/InternalHelpers.sol";

contract Arm is InternalHelpers {

    constructor (address _swapper) Swapper(_swapper) {
        // 
    }
    
    function payProduct(uint productId, uint shippingCost, bytes memory signedMessage) external payable {

    }

}