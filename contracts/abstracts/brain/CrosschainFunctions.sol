// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";

abstract contract CrosschainFunctions is InternalHelpers {
    
    function xcallPayReceiver(
        uint productId, 
        address buyer, 
        uint32 originDomain, 
        uint shippingCost, 
        bytes memory signedMessage,
        uint price,
        address destinationToken
    ) external payable onlyRegisteredArm {
        _payProduct(
            productId, 
            buyer, 
            originDomain, 
            shippingCost, 
            signedMessage,
            price,
            destinationToken
        );
    }

}