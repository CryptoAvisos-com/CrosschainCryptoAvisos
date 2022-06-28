// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SendNReceive {

    address private constant _NATIVE = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function _addTokens(address token, uint amount, address from) internal {
        if (token == _NATIVE) {
            //Pay with ether (or native coin)
            require(msg.value == amount, "!msg.value");
        }else{
            //Pay with token
            IERC20(token).transferFrom(from, address(this), amount);
        }
    }

    function _sendTokens(address token, uint amount, address to) internal {
        if (token == _NATIVE) {
            //Pay with ether (or native coin)
            payable(to).transfer(amount);
        }else{
            //Pay with token
            IERC20(token).transfer(to, amount);
        }
    }
    
}