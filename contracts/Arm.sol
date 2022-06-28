// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./abstracts/arm/InternalHelpers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Arm is InternalHelpers, Ownable {

    constructor (address _swapper, address _wNATIVE, address _connext) Swapper(_swapper, _wNATIVE) XCall(_connext) { }
    
    function payProduct(
        uint productId, 
        uint shippingCost, 
        bytes memory signedShippingCost, 
        uint originTokenInAmount, // see getOptimalInput in Swapper.sol
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

    function addSettlementToken(address tokenToAdd) external onlyOwner {
        _addSettlementToken(tokenToAdd);
    }

    function removeSettlementToken(address tokenToRemove) external onlyOwner {
        _removeSettlementToken(tokenToRemove);
    }

}