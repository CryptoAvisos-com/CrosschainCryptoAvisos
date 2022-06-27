// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../../interfaces/IBrain.sol";

abstract contract Base {
    
    IBrain public brain;
    uint32 public armDomain; // this contract domain
    uint32 public brainDomain; // brain contract domain
    bytes4 selector = IBrain.xcallPayReceiver.selector;

    event PayProduct(uint productId, uint shippingCost, uint originTokenInAmount, uint price, address originToken, address destinationToken, uint relayerFee);

}