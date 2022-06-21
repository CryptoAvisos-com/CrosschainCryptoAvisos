// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./InternalHelpers.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract SingleFunctions is InternalHelpers {

    /// @notice Used for admin as first step to set fee (1/2)
    /// @dev Prepare to set fee (wait 7 days to set. Timelock kind of)
    /// @param newFee new fee to prepare
    function prepareFee(uint newFee) external onlyOwner {
        lastUnlockTimeFee = block.timestamp + 7 days;
        lastFeeToSet = newFee;
        emit PreparedFee(newFee, lastUnlockTimeFee);
    }

    /// @notice Used for admin as second step to set fee (2/2)
    /// @dev Set fee after 7 days
    function implementFee() external onlyOwner {
        require(lastUnlockTimeFee > 0, "!prepared");
        require(lastUnlockTimeFee <= block.timestamp, "!unlocked");
        _setFee(lastFeeToSet);
        lastUnlockTimeFee = 0;
    }

    /// @notice Used for admin to claim fees originated from sales
    /// @param token address of token to claim
    /// @param quantity quantity to claim
    function claimFees(address token, uint quantity) external payable onlyOwner {
        require(claimableFee[token] >= quantity, "!funds");
        claimableFee[token] -= quantity;

        if(token == address(0)){
            //ETH
            payable(msg.sender).transfer(quantity);
        }else{
            //ERC20
            IERC20(token).transfer(msg.sender, quantity);
        }
        emit FeesClaimed(msg.sender, token, quantity);
    }

    /// @notice Used for admin to claim shipping cost
    /// @param token address of token to claim
    /// @param quantity quantity to claim
    function claimShippingCost(address token, uint quantity) external payable onlyOwner {
        require(claimableShippingCost[token] >= quantity, "!funds");
        claimableShippingCost[token] -= quantity;

        if(token == address(0)){
            //ETH
            payable(msg.sender).transfer(quantity);
        }else{
            //ERC20
            IERC20(token).transfer(msg.sender, quantity);
        }
        emit FeesClaimed(msg.sender, token, quantity);
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
        _payProduct(productId, shippingCost, signedMessage);
    }

    /// @notice Release pay (sends money, without fee, to the seller)
    /// @param ticketId TicketId (returned on `payProduct`)
    function releasePay(uint ticketId) external onlyOwner {
        Ticket memory ticket = productTicketsMapping[ticketId];
        require(ticket.buyer != address(0), "!exist");

        Product memory product = productMapping[ticket.productId];
        require(Status.WAITING == ticket.status, "!waiting");
        uint finalPrice = ticket.pricePaid - ticket.feeCharged;

        if (ticket.tokenPaid == address(0)) {
            //Pay with ether (or native coin)
            product.seller.transfer(finalPrice);
        }else{
            //Pay with token
            IERC20(ticket.tokenPaid).transfer(product.seller, finalPrice);
        }

        claimableFee[product.token] += ticket.feeCharged;
        claimableShippingCost[product.token] += ticket.shippingCost;

        ticket.status = Status.SOLD;
        productTicketsMapping[ticketId] = ticket;
        emit PayReleased(ticket.productId, ticketId);
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
        Ticket memory ticket = productTicketsMapping[ticketId];

        require(ticket.productId != 0, "!ticketId");
        require(Status.WAITING == ticket.status, "!waiting");

        uint toRefund = ticket.pricePaid + ticket.shippingCost;

        if(ticket.tokenPaid == address(0)){
            //ETH
            ticket.buyer.transfer(toRefund);
        }else{
            //ERC20
            IERC20(ticket.tokenPaid).transfer(ticket.buyer, toRefund);
        }
        ticket.status = Status.REFUNDED;
        
        productTicketsMapping[ticketId] = ticket;
        emit ProductRefunded(ticket.productId, ticketId);
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
        sellerWhitelist[seller] = true;
        emit SellerWhitelistAdded(seller);
    }

    /// @notice Remove a seller address to the whitelisted in order to manage their own products
    /// @param seller Address of the seller
    function removeWhitelistedSeller(address seller) external onlyOwner {
        sellerWhitelist[seller] = false;
        emit SellerWhitelistRemoved(seller);
    }

    function addArm(uint32 domain, address contractAddress) external onlyOwner {
        require(domain != 0, "!domain");
        require(contractAddress != address(0), "!contractAddress");
        require(armRegistry[domain] == address(0), "alreadyExists");
        armRegistry[domain] = contractAddress;
        emit AddedArm(domain, contractAddress);
    }

    function updateArm(uint32 domain, address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "!contractAddress");
        require(armRegistry[domain] != address(0), "!exists");
        armRegistry[domain] = contractAddress;
        emit UpdatedArm(domain, contractAddress);
    }

}