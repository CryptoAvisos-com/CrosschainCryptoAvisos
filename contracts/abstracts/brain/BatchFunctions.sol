// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";

abstract contract BatchFunctions is InternalHelpers {
    
    /// @notice Submit products in batch
    /// @dev Create a new product in loop, revert if already exists.
    /// @param productsId ID of the product in CA DB
    /// @param products array of Product struct to create
    function batchSubmitProduct(uint[] memory productsId, Product[] memory products) external onlyWhitelisted {
        require(productsId.length == products.length, "!productsId");
        for (uint256 i = 0; i < productsId.length; i++) {
            _submitProduct(productsId[i], payable(products[i].seller), products[i].price, products[i].token, products[i].stock, products[i].outputPaymentDomain, products[i].enabled);
        }
    }

    /// @notice Used by admin to update values of a product, in batch
    /// @dev `productId` needs to be already in contract
    /// @param productsId ID of the product in CA DB
    /// @param products array of Product struct to update
    function batchUpdateProduct(uint[] memory productsId, Product[] memory products) external onlyProductOwnerBatch(productsId) {
        require(productsId.length == products.length, "!productsId");
        for (uint256 i = 0; i < productsId.length; i++) {
            _updateProduct(productsId[i], payable(products[i].seller), products[i].price, products[i].token, products[i].stock, products[i].outputPaymentDomain, products[i].enabled);
        }
    }

    /// @notice Add units to stock in a specific product, in batch
    /// @param productsId ID of the product in CA DB
    /// @param stockToAdd How many units add to stock
    function batchAddStock(uint[] memory productsId, uint16[] memory stockToAdd) external onlyProductOwnerBatch(productsId) {
        _checkArrayLength(productsId, stockToAdd);
        for (uint256 i = 0; i < productsId.length; i++) {
            _addStock(productsId[i], stockToAdd[i]);
        }
    }

    /// @notice Remove units to stock in a specific product, in batch
    /// @param productsId ID of the product in CA DB
    /// @param stockToRemove How many units remove from stock
    function batchRemoveStock(uint[] memory productsId, uint16[] memory stockToRemove) external onlyProductOwnerBatch(productsId) {
        _checkArrayLength(productsId, stockToRemove);
        for (uint256 i = 0; i < productsId.length; i++) {
            _removeStock(productsId[i], stockToRemove[i]);
        }
    }

    /// @notice This function enable or disable a product, in batch
    /// @dev Modifies value of `enabled` in Product Struct
    /// @param productsId ID of the product in CA DB
    /// @param isEnabled value to set
    function batchSwitchEnable(uint[] memory productsId, bool isEnabled) external onlyProductOwnerBatch(productsId) {
        for (uint256 i = 0; i < productsId.length; i++) {
            _switchEnable(productsId[i], isEnabled);
        }
    }

}