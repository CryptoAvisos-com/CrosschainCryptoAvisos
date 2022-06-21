// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Base.sol";

abstract contract PublicViewHelpers is Base {
    
    /// @notice Get all productIds loaded in the contract
    /// @return an array of productIds
    function getProductsIds() external view returns (uint[] memory) {
        return productsIds;
    }

    /// @notice Get all ticketsIds loaded in the contract
    /// @return an array of ticketsIds
    function getTicketsIds() external view returns (uint[] memory) {
        return ticketsIds;
    }

    /// @notice Get all ticketsIds filtered by `productId`
    /// @param productId ID of the product in CA DB
    /// @return an array of ticketsIds
    function getTicketsIdsByProduct(uint productId) external view returns (uint[] memory) {
        // Count how many of them are
        uint count = 0;
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            if (productTicketsMapping[ticketsIds[i]].productId == productId) {
                count++;
            }
        }

        // Add to array
        uint index = 0;
        uint[] memory _ticketsIds = new uint[](count);
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            if (productTicketsMapping[ticketsIds[i]].productId == productId) {
                _ticketsIds[index] = ticketsIds[i];
                index++;
            }
        }

        return _ticketsIds;
    }

    /// @notice Get all ticketsIds filtered by `buyer`
    /// @param user address of user to filter
    /// @return an array of ticketsIds
    function getTicketsIdsByAddress(address user) external view returns (uint[] memory) {
        // Count how many of them are
        uint count = 0;
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            if (productTicketsMapping[ticketsIds[i]].buyer == user) {
                count++;
            }
        }

        // Add to array
        uint index = 0;
        uint[] memory _ticketsIds = new uint[](count);
        for (uint256 i = 0; i < ticketsIds.length; i++) {
            if (productTicketsMapping[ticketsIds[i]].buyer == user) {
                _ticketsIds[index] = ticketsIds[i];
                index++;
            }
        }

        return _ticketsIds;
    }

}