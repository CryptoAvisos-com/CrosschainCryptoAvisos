// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../../interfaces/IBrain.sol";
import { IConnextHandler } from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
import { IExecutor } from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IExecutor.sol";

abstract contract Base {
    
    IBrain public brain;
    uint32 public armDomain; // this contract domain
    uint32 public brainDomain; // brain contract domain
    address public executor;
    IConnextHandler public connext;
    bytes4 selector = IBrain.xcallPayReceiver.selector;

    constructor () {

    }

}