// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

interface IBrain {
    function xcallPayReceiver(
        uint256 productId,
        address buyer,
        uint32 originDomain,
        uint256 shippingCost,
        bytes memory signedMessage
    ) external payable;
}