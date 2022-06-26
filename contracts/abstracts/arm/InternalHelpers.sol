// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Base.sol";
import "../Swapper.sol";
import "../SettlementTokens.sol";
import "../XCall.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract InternalHelpers is Base, Swapper, SettlementTokens, XCall {

    function _payProduct(
        uint productId,
        uint shippingCost,
        bytes memory signedShippingCost,
        uint originTokenInAmount,
        uint price,
        address originToken,
        address destinationToken,
        uint relayerFee
    ) internal {
        // CHECKS
        require(price != 0, "!price");
        require(originTokenInAmount != 0, "!price");
        require(destinationToken != address(0), "!destinationToken");
        require(_isSettlementToken(destinationToken), "!settlementToken");
        if (destinationToken == NATIVE) { require(msg.value == price, "!msg.value"); }
        if (originToken == NATIVE) { require(msg.value == originTokenInAmount, "!msg.value"); }

        //INTERACTIONS
        if (originToken != address(0) && !_isSettlementToken(originToken)) { // not a settlement token, need to swap
            IERC20(originToken).transferFrom(msg.sender, address(this), originTokenInAmount);

            address[] memory path = new address[](2);
            path[0] = originToken;
            path[1] = destinationToken;
            _swap(originToken, destinationToken, originTokenInAmount, price, path);
        } else { // settlement token, no need to swap
            IERC20(destinationToken).transferFrom(msg.sender, address(this), price);
        }

        // xcall
        _approveMax(destinationToken, address(connext));
        bytes memory _calldata = abi.encodeWithSelector(selector, productId, shippingCost, signedShippingCost, destinationToken);
        _xcall(destinationToken, _calldata, relayerFee, address(brain), armDomain, brainDomain, price);

        emit PayProduct(productId, shippingCost, originTokenInAmount, price, originToken == address(0) ? destinationToken : originToken, destinationToken, relayerFee);
    }

}