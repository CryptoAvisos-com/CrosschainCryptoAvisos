// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";

abstract contract SingleFunctions is InternalHelpers {

    /// @notice Used for admin as first step to set fee (1/2)
    /// @dev Prepare to set fee (wait 7 days to set. Timelock kind of)
    /// @param newFee new fee to prepare
    function prepareFee(uint newFee) external onlyOwner {
        _prepareFee(newFee);
    }

    /// @notice Used for admin as second step to set fee (2/2)
    /// @dev Set fee after 7 days
    function implementFee() external onlyOwner {
        _implementFee();
    }

    /// @notice Used for admin to claim fees originated from sales
    /// @param token address of token to claim
    /// @param quantity quantity to claim
    function claimFees(address token, uint quantity) external onlyOwner {
        _claimFees(token, quantity);
    }

    /// @notice Used for admin to claim shipping cost
    /// @param token address of token to claim
    /// @param quantity quantity to claim
    function claimShippingCost(address token, uint quantity) external onlyOwner {
        _claimShippingCost(token, quantity);
    }

    /// @notice Used for admin to change allowed signer account
    /// @param _allowedSigner address of new signer
    function changeAllowedSigner(address _allowedSigner) external onlyOwner {
        _changeAllowedSigner(_allowedSigner);
    }

    /// @notice Submit a product
    /// @dev Create a new product, revert if already exists
    /// @param productId ID of the product in CA DB
    /// @param seller seller address of the product
    /// @param price price (with corresponding ERC20 decimals)
    /// @param token address of the token
    /// @param stock how much units of the product
    function submitProduct(uint productId, address payable seller, uint price, address token, uint16 stock, uint32 paymentDomain) external onlyWhitelisted {
        _submitProduct(productId, seller, price, token, stock, paymentDomain, true);
    }

    /// @notice This function enable or disable a product
    /// @dev Modifies value of `enabled` in Product Struct
    /// @param productId ID of the product in CA DB
    /// @param isEnabled value to set
    function switchEnable(uint productId, bool isEnabled) external onlyProductOwner(productId) {
        _switchEnable(productId, isEnabled);
    }

    /// @notice Public function to pay a product
    /// @dev It generates a ticket, can be pay with ETH or ERC20. Verifies the shipping cost
    /// @param productId ID of the product in CA DB
    /// @param shippingCost Shipping cost in WEI
    /// @param signedMessage Signed message (hash)
    function payProduct(uint productId, uint shippingCost, bytes memory signedMessage) external payable {
        _payProduct(productId, msg.sender, brainDomain, shippingCost, signedMessage);
    }

    /// @notice Release pay (sends money, without fee, to the seller)
    /// @param ticketId TicketId (returned on `payProduct`)
    function releasePay(uint ticketId) external onlyOwner {
        _releasePay(ticketId);
    }

    /// @notice Used by admin to update values of a product
    /// @dev `productId` needs to be already in contract
    /// @param productId ID of the product in CA DB
    /// @param seller seller address of the product
    /// @param price price (with corresponding ERC20 decimals)
    /// @param token address of the token
    /// @param stock how much units of the product
    function updateProduct(uint productId, address payable seller, uint price, address token, uint16 stock, uint32 paymentDomain) external onlyProductOwner(productId) {
        //Update a product
        _updateProduct(productId, seller, price, token, stock, paymentDomain, true);
    }

    /// @notice Refunds pay (sends money, without fee, to the buyer)
    /// @param ticketId TicketId (returned on `payProduct`)
    function refundProduct(uint ticketId) external onlyOwner {
        _refundProduct(ticketId);
    }

    /// @notice Add units to stock in a specific product
    /// @param productId ID of the product in CA DB
    /// @param stockToAdd How many units add to stock
    function addStock(uint productId, uint16 stockToAdd) external onlyProductOwner(productId) {
        //Add stock to a product
        _addStock(productId, stockToAdd);
    }

    /// @notice Remove units to stock in a specific product
    /// @param productId ID of the product in CA DB
    /// @param stockToRemove How many units remove from stock
    function removeStock(uint productId, uint16 stockToRemove) external onlyProductOwner(productId) {
        //Add stock to a product
        _removeStock(productId, stockToRemove);
    }
    
    /// @notice Add a seller address to the whitelisted in order to manage their own products
    /// @param seller Address of the seller
    function addWhitelistedSeller(address seller) external onlyOwner {
        _addWhitelistedSeller(seller);
    }

    /// @notice Remove a seller address to the whitelisted in order to manage their own products
    /// @param seller Address of the seller
    function removeWhitelistedSeller(address seller) external onlyOwner {
        _removeWhitelistedSeller(seller);
    }

    function addArm(uint32 domain, address contractAddress) external onlyOwner {
        _addArm(domain, contractAddress);
    }

    function updateArm(uint32 domain, address contractAddress) external onlyOwner {
        _updateArm(domain, contractAddress);
    }

}