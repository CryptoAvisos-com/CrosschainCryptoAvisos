// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

abstract contract SettlementTokens {

    address[] public settlementTokens;

    function _addSettlementToken(address _tokenToAdd) internal {
        settlementTokens.push(_tokenToAdd);
    }

    function _removeSettlementToken(address _tokenToRemove) internal {
        for (uint256 i = 0; i < settlementTokens.length; i++) {
            if (settlementTokens[i] == _tokenToRemove) {
                settlementTokens[i] = address(0);
                return;
            }
        }
    }

    function _isSettlementToken(address _token) internal view returns (bool) {
        for (uint256 i = 0; i < settlementTokens.length; i++) {
            if (settlementTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

}