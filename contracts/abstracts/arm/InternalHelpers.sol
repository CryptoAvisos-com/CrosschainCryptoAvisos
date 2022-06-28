// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Base.sol";
import "../Swapper.sol";
import "../XCall.sol";
import "../SettlementTokens.sol";
import "../SendNReceive.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract InternalHelpers is Base, Swapper, XCall, SettlementTokens, SendNReceive {

    function _payProduct(
        uint productId,
        uint shippingCost,
        bytes memory signedShippingCost,
        uint originTokenInAmount,
        uint price,
        address[] memory path,
        uint relayerFee
    ) internal {
        // CHECKS
        address originToken = path[0];
        address destinationToken = path[path.length - 1];
        require(price != 0, "!price");
        require(originTokenInAmount != 0, "!price");
        require(destinationToken != address(0), "!destinationToken");
        require(_isSettlementToken(destinationToken), "!settlementToken");
        if (destinationToken == NATIVE) { require(msg.value == price, "!msg.value"); }
        if (originToken == NATIVE) { require(msg.value == originTokenInAmount, "!msg.value"); }

        // INTERACTIONS
        if (originToken != address(0) && !_isSettlementToken(originToken)) { // not a settlement token, need to swap
            _addTokens(originToken, originTokenInAmount, msg.sender);
            path = _changeToWrap(path);
            _swap(originToken, destinationToken, originTokenInAmount, price, path);
        } else { // settlement token, no need to swap
            _addTokens(destinationToken, price, msg.sender);
        }

        // xcall
        _approveMax(destinationToken, address(connext));
        bytes memory _calldata = abi.encodeWithSelector(selector, productId, shippingCost, signedShippingCost, destinationToken);
        _xcall(destinationToken, _calldata, relayerFee, address(brain), armDomain, brainDomain, price);

        emit PayProduct(productId, shippingCost, originTokenInAmount, price, originToken == address(0) ? destinationToken : originToken, destinationToken, relayerFee);
    }

}