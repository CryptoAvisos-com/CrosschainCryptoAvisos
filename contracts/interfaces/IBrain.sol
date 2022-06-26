// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IBrain {
    function xcallPayReceiver(
        uint256 productId,
        uint256 shippingCost,
        bytes memory signedMessage,
        address destinationToken
    ) external payable;
}