// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IBrain {
    function payProduct(uint productId, uint shippingCost, bytes memory signedMessage) external payable;
}