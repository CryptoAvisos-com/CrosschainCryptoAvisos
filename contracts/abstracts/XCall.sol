// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import { IConnextHandler } from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
import { CallParams, XCallArgs } from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";

abstract contract XCall {

    IConnextHandler public connext;
    address public executor;

    constructor (address _connext) {
        connext = IConnextHandler(_connext);
        executor = address(connext.executor());
    }

    function _xcall(
        address token, 
        bytes memory callData, 
        uint relayerFee,
        address to,
        uint32 originDomain,
        uint32 destinationDomain,
        uint amount
    ) internal {
        CallParams memory callParams = CallParams({
            to: to,
            callData: callData,
            originDomain: originDomain,
            destinationDomain: destinationDomain,
            recovery: msg.sender,
            callback: address(0),
            callbackFee: 0,
            forceSlow: true,
            receiveLocal: false
        });

        XCallArgs memory xcallArgs = XCallArgs({
            params: callParams,
            transactingAssetId: token,
            amount: amount,
            relayerFee: relayerFee
        });

        connext.xcall(xcallArgs);
    }

}