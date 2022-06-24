// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./abstracts/arm/InternalHelpers.sol";

contract Arm is InternalHelpers {

    constructor (address _swapper, address _connext) Swapper(_swapper) XCall(_connext) { }
    
    function payProduct(
        uint productId, 
        uint shippingCost, 
        bytes memory signedMessage, 
        uint originTokenInAmount, 
        uint price, 
        address originToken, 
        address destinationToken, 
        uint relayerFee
    ) external payable {
        _payProduct(
            productId, 
            shippingCost, 
            signedMessage, 
            originTokenInAmount, 
            price, 
            originToken, 
            destinationToken, 
            relayerFee
        );
    }

}