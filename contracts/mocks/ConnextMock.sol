//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import { IConnextHandler } from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnextHandler.sol";
import { CallParams, XCallArgs } from "@connext/nxtp-contracts/contracts/core/connext/libraries/LibConnextStorage.sol";
import "hardhat/console.sol";

contract ConnextMock {

    address public executor;
    address public originSender;
    uint32 public origin;
    XCallArgs public data;

    constructor () { }

    function changeOriginSender(address _originSender) public {
        originSender = _originSender;
    }

    function changeExecutor(address _executor) public {
        executor = _executor;
    }

    function changeOrigin(uint32 _origin) public {
        origin = _origin;
    }

    function getExecutor() external view returns (address) {
        return executor;
    }

    function xcall(XCallArgs memory xcallArgs) external payable returns (bytes32) {
        data = xcallArgs;
        return bytes32("");
    }

}