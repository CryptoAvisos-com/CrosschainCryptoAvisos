// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./abstracts/arm/InternalHelpers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Arm
/// @dev This contract needs to be deployed on every arm chain, and will perform xCall to the Brain
contract Arm is InternalHelpers, Ownable {

    constructor (address _swapper, address _wNATIVE, address _connext) Swapper(_swapper, _wNATIVE) XCall(_connext) { }
    
    /// @notice Public function to pay a product
    /// @param productId ID of the product in CA DB
    /// @param shippingCost Shipping cost in WEI
    /// @param signedShippingCost Signed message with shipping cost, to prevent cheating (hash)
    /// @param originTokenInAmount amount of token in (see getOptimalInput in Swapper.sol)
    /// @param price product price
    /// @param path path of pairs
    /// @param relayerFee fee to pay to relayer
    function payProduct(
        uint productId, 
        uint shippingCost, 
        bytes memory signedShippingCost, 
        uint originTokenInAmount, 
        uint price, 
        address[] memory path,
        uint relayerFee
    ) external payable {
        _payProduct(
            productId, 
            shippingCost, 
            signedShippingCost, 
            originTokenInAmount, 
            price, 
            path, 
            relayerFee
        );
    }

    /// @notice Add a settlement token (local address)
    /// @param tokenToAdd contract address of settlement token in arm chain
    function addSettlementToken(address tokenToAdd) external onlyOwner {
        _addSettlementToken(tokenToAdd);
    }

    /// @notice Remove a settlement token (local address)
    /// @param tokenToRemove contract address of settlement token in arm chain
    function removeSettlementToken(address tokenToRemove) external onlyOwner {
        _removeSettlementToken(tokenToRemove);
    }

}