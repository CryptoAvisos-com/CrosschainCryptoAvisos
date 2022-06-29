// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";

abstract contract CrosschainFunctions is InternalHelpers {
    
    /// @notice Used by connext executor to xcall
    /// @param productId ID of the product in CA DB
    /// @param shippingCost Shipping cost in WEI
    /// @param signedShippingCost Signed message with shipping cost, to prevent cheating (hash)
    /// @param destinationToken token address of token transferred (foreign chain address)
    function xcallPayReceiver(
        uint productId,
        uint shippingCost, 
        bytes memory signedShippingCost,
        address destinationToken
    ) external payable onlyRegisteredArm {
        _payProduct(
            productId,
            shippingCost, 
            signedShippingCost,
            destinationToken
        );
    }

}