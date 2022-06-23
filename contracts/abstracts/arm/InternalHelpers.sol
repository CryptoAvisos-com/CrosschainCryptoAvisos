// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Base.sol";
import "../Swapper.sol";
import "../../libraries/Iterable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CallParams, XCallArgs } from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";

abstract contract InternalHelpers is Base, Swapper {

    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private allowedTokens;

    function _xcall(IERC20 token, uint productId, uint shippingCost, bytes memory signedMessage, uint relayerFee) internal {
        // token.transferFrom(msg.sender, address(this), amount);

        bytes memory callData = abi.encodeWithSelector(selector, productId, shippingCost, signedMessage);

        CallParams memory callParams = CallParams({
            to: address(brain),
            callData: callData,
            originDomain: armDomain,
            destinationDomain: brainDomain,
            recovery: msg.sender,
            callback: address(0),
            callbackFee: 0,
            forceSlow: true,
            receiveLocal: false
        });

        XCallArgs memory xcallArgs = XCallArgs({
            params: callParams,
            transactingAssetId: address(token),
            amount: 0,
            relayerFee: relayerFee
        });

        connext.xcall(xcallArgs);
    }

    function _addAllowedToken() internal {

    }

    function _removeAllowedToken() internal {

    }

}