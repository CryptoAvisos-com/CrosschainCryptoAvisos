// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

abstract contract SettlementTokens {

    address[] public settlementTokens;

    function _addSettlementToken(address _tokenToAdd) internal {
        require(_tokenToAdd != address(0), "!zeroAddress");
        require(!_isSettlementToken(_tokenToAdd), "exists");
        settlementTokens.push(_tokenToAdd);
    }

    function _removeSettlementToken(address _tokenToRemove) internal {
        require(_tokenToRemove != address(0), "!zeroAddress");
        for (uint256 i = 0; i < settlementTokens.length; i++) {
            if (settlementTokens[i] == _tokenToRemove) {
                settlementTokens[i] = address(0);
                return;
            }
        }
    }

    function _isSettlementToken(address _token) internal view returns (bool) {
        if (_token == address(0)) { return false; }
        for (uint256 i = 0; i < settlementTokens.length; i++) {
            if (settlementTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function isSettlementToken(address _token) public view returns (bool) {
        return _isSettlementToken(_token);
    }

    function getSettlementTokens() public view returns (address[] memory) {
        return settlementTokens;
    }

}