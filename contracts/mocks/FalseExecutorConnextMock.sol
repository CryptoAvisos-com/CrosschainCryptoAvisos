//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract FalseExecutorConnextMock {

    address public executor;
    address public originSender;
    uint32 public origin;

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

}