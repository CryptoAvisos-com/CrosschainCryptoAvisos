// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/ISwapper.sol";
import "../interfaces/IPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Swapper {

    ISwapper public swapper;
    uint public constant max = type(uint).max;
    address public constant NATIVE = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    event Swapped(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOut);

    constructor (address _swapper) {
        swapper = ISwapper(_swapper);
    }

    function _swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOut, address[] memory path) internal {
        address receiver = address(this);
        uint deadline = block.timestamp;
        
        uint balanceBefore =  _tokenOut == NATIVE ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this));

        _approveMax(_tokenIn, address(swapper));

        if (_tokenIn == NATIVE) {
            // ETH -> Token
            require(_amountIn == msg.value, "!msg.value");
            swapper.swapETHForExactTokens(_amountOut, path, receiver, deadline);

        } else if (_tokenIn != NATIVE && _tokenOut != NATIVE) {
            // Token -> Token
            swapper.swapTokensForExactTokens(_amountOut, _amountIn, path, receiver, deadline);

        } else if (_tokenIn != NATIVE && _tokenOut == NATIVE){
            // Token -> ETH
            swapper.swapTokensForExactETH(_amountOut, _amountIn, path, receiver, deadline);

        }

        uint balanceAfter =  _tokenOut == NATIVE ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this));
        require(balanceAfter - balanceBefore == _amountOut, "!balanceAfter");

        emit Swapped(_tokenIn, _tokenOut, _amountIn, _amountOut);
    }

    function _approveMax(address _token, address spender) internal {
        if (_token != NATIVE) {
            IERC20 token = IERC20(_token);
            
            if (token.allowance(address(this), spender) != max) {
                IERC20(_token).approve(spender, max);
            }
        }
    }

}