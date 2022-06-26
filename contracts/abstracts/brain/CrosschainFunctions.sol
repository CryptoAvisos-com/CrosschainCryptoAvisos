// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";

abstract contract CrosschainFunctions is InternalHelpers {
    
    function xcallPayReceiver(
        uint productId,
        uint shippingCost, 
        bytes memory signedMessage,
        address destinationToken
    ) external payable onlyRegisteredArm {
        _payProduct(
            productId,
            shippingCost, 
            signedMessage,
            destinationToken
        );
    }

}