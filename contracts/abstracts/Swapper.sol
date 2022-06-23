// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "../interfaces/ISwapper.sol";
import "../interfaces/IPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Swapper {

    ISwapper public swapper;

    constructor (address _swapper) {
        swapper = ISwapper(_swapper);
    }

    function _swap(address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOut, address[] calldata path) internal {
        address receiver = address(this);
        uint deadline = block.timestamp;
        
        uint balanceBefore =  _tokenOut == address(0) ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this));

        if (_tokenIn == address(0)) {
            // ETH -> Token
            require(_amountIn == msg.value, "!msg.value");
            swapper.swapETHForExactTokens(_amountOut, path, receiver, deadline);

        } else if (_tokenIn != address(0) && _tokenOut != address(0)) {
            // Token -> Token
            swapper.swapTokensForExactTokens(_amountOut, _amountIn, path, receiver, deadline);

        } else if (_tokenIn != address(0) && _tokenOut == address(0)){
            // Token -> ETH
            swapper.swapTokensForExactETH(_amountOut, _amountIn, path, receiver, deadline);

        }

        uint balanceAfter =  _tokenOut == address(0) ? address(this).balance : IERC20(_tokenOut).balanceOf(address(this));
        require(balanceAfter - balanceBefore == _amountOut, "!balanceAfter");
    }

}