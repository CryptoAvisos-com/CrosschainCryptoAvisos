// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Base.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IExecutor } from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IExecutor.sol";

abstract contract InternalHelpers is Base, Ownable {

    using ECDSA for bytes32;

    modifier onlyWhitelisted() {
        require(owner() == msg.sender || sellerWhitelist[msg.sender], '!whitelisted');
        _;
    }

    modifier onlyProductOwner(uint productId) {
        _checkOwnership(productId);
        _;
    }

    modifier onlyProductOwnerBatch(uint[] memory productsId) {
        for (uint256 i = 0; i < productsId.length; i++) {
            _checkOwnership(productsId[i]);
        }
        _;
    }

    modifier onlyRegisteredArm() {
        require(msg.sender == executor, "!executor");
        uint32 domain = IExecutor(msg.sender).origin();
        address arm = IExecutor(msg.sender).originSender();
        require(armRegistry[domain] == arm, "!registered");
        _;
    }
    
    function _checkOwnership(uint productId) internal view {
        require(productId != 0, "!productId");
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "!exist");
        require(owner() == msg.sender || (sellerWhitelist[msg.sender] && product.seller == msg.sender), "!whitelisted");
    }

    function _prepareFee(uint newFee) internal {
        // EFFECTS
        lastUnlockTimeFee = block.timestamp + 7 days;
        lastFeeToSet = newFee;

        emit PreparedFee(newFee, lastUnlockTimeFee);
    }

    function _implementFee() internal {
        // CHECKS
        require(lastUnlockTimeFee > 0, "!prepared");
        require(lastUnlockTimeFee <= block.timestamp, "!unlocked");

        // EFFECTS
        _setFee(lastFeeToSet);
        lastUnlockTimeFee = 0;
    }

    function _claimFees(address token, uint quantity) internal {
        // CHECKS
        require(claimableFee[token] >= quantity, "!funds");

        // EFFECTS
        claimableFee[token] -= quantity;

        // INTERACTIONS
        _sendTokens(token, quantity, msg.sender);

        emit FeesClaimed(msg.sender, token, quantity);
    }

    function _claimShippingCost(address token, uint quantity) internal {
        // CHECKS
        require(claimableShippingCost[token] >= quantity, "!funds");

        // EFFECTS
        claimableShippingCost[token] -= quantity;

        // INTERACTIONS
        _sendTokens(token, quantity, msg.sender);

        emit ShippingCostClaimed(msg.sender, token, quantity);
    }

    function _setFee(uint newFee) internal {
        // CHECKS
        require(newFee <= 100e18, "!fee"); // Set fee. Example: 10e18 = 10%

        // EFFECTS
        uint previousFee = fee;
        fee = newFee;

        emit FeeSetted(previousFee, newFee);
    }

    function _addTokens(address token, uint amount, address from) internal {
        if (token == address(0)) {
            //Pay with ether (or native coin)
            require(msg.value == amount, "!msg.value");
        }else{
            //Pay with token
            IERC20(token).transferFrom(from, address(this), amount);
        }
    }

    function _sendTokens(address token, uint amount, address to) internal {
        if (token == address(0)) {
            //Pay with ether (or native coin)
            payable(to).transfer(amount);
        }else{
            //Pay with token
            IERC20(token).transfer(to, amount);
        }
    }

    function _payProduct(uint productId, uint shippingCost, bytes memory signedMessage) internal {
        // CHECKS
        require(executed[signedMessage] == false, "!signedMessage");
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "!exist");
        require(product.enabled, "!enabled");
        require(product.stock != 0, "!stock");

        bytes32 _hash = _getHash(productId, msg.sender, shippingCost, block.chainid, nonce); // verifing signature
        bytes32 ethSignedHash = _hash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signedMessage);
        require(allowedSigner == signer, "!allowedSigner");

        // EFFECTS
        uint price = product.price + shippingCost;
        uint toFee = product.price * fee / 100e18;

        uint ticketId = uint(keccak256(abi.encode(productId, msg.sender, block.number, product.stock))); // Create ticket
        productTicketsMapping[ticketId] = Ticket(productId, Status.WAITING, payable(msg.sender), product.token, toFee, product.price, shippingCost);
        ticketsIds.push(ticketId);

        product.stock -= 1;
        executed[signedMessage] = true;
        nonce++;
        productMapping[productId] = product;

        // INTERACTIONS
        _addTokens(product.token, price, msg.sender);

        emit ProductPaid(productId, ticketId);
    }

    function _submitProduct(uint productId, address payable seller, uint price, address token, uint16 stock, uint32 paymentDomain, bool enabled) internal {
        // CHECKS
        require(productId != 0, "!productId");
        require(price != 0, "!price");
        require(seller != address(0), "!seller");
        require(stock != 0, "!stock");
        require(productMapping[productId].seller == address(0), "alreadyExist");
        require(owner() == msg.sender || seller == msg.sender, "!whitelisted");

        // EFFECTS
        productMapping[productId] = Product(price, seller, token, enabled, paymentDomain, stock);
        productsIds.push(productId);

        emit ProductSubmitted(productId);
    }

    function _updateProduct(uint productId, address payable seller, uint price, address token, uint16 stock, uint32 paymentDomain, bool enabled) internal {
        // CHECKS
        require(price != 0, "!price");
        require(seller != address(0), "!seller");

        // EFFECTS
        productMapping[productId] = Product(price, seller, token, enabled, paymentDomain, stock);

        emit ProductUpdated(productId);
    }

    function _refundProduct(uint ticketId) internal {
        // CHECKS
        Ticket memory ticket = productTicketsMapping[ticketId];

        require(ticket.productId != 0, "!ticketId");
        require(Status.WAITING == ticket.status, "!waiting");

        // EFFECTS
        uint toRefund = ticket.pricePaid + ticket.shippingCost;
        ticket.status = Status.REFUNDED;
        
        productTicketsMapping[ticketId] = ticket;

        // INTERACTIONS
        _sendTokens(ticket.tokenPaid, toRefund, ticket.buyer);

        emit ProductRefunded(ticket.productId, ticketId);
    }

    function _addStock(uint productId, uint16 stockToAdd) internal {
        // CHECKS
        Product memory product = productMapping[productId];
        require(stockToAdd != 0, "!stockToAdd");

        // EFFECTS
        product.stock += stockToAdd;
        productMapping[productId] = product;

        emit StockAdded(productId, stockToAdd);
    }

    function _removeStock(uint productId, uint16 stockToRemove) internal {
        // CHECKS
        Product memory product = productMapping[productId];
        require(product.stock >= stockToRemove, "!stockToRemove");

        // EFFECTS
        product.stock -= stockToRemove;
        productMapping[productId] = product;

        emit StockRemoved(productId, stockToRemove);
    }

    function _switchEnable(uint productId, bool isEnabled) internal {
        // EFFECTS
        Product memory product = productMapping[productId];
        product.enabled = isEnabled;
        productMapping[productId] = product;

        emit SwitchChanged(productId, isEnabled);
    }

    function _releasePay(uint ticketId) internal {
        // CHECKS
        Ticket memory ticket = productTicketsMapping[ticketId];
        require(ticket.buyer != address(0), "!exist");

        Product memory product = productMapping[ticket.productId];
        require(Status.WAITING == ticket.status, "!waiting");

        // EFFECTS
        uint finalPrice = ticket.pricePaid - ticket.feeCharged;

        claimableFee[product.token] += ticket.feeCharged;
        claimableShippingCost[product.token] += ticket.shippingCost;

        ticket.status = Status.SOLD;
        productTicketsMapping[ticketId] = ticket;

        // INTERACTIONS
        _sendTokens(ticket.tokenPaid, finalPrice, product.seller);
        
        emit PayReleased(ticket.productId, ticketId);
    }

    function _addArm(uint32 domain, address contractAddress) internal {
        // CHECKS
        require(domain != 0, "!domain");
        require(contractAddress != address(0), "!contractAddress");
        require(armRegistry[domain] == address(0), "alreadyExists");

        // EFFECTS
        armRegistry[domain] = contractAddress;

        emit AddedArm(domain, contractAddress);
    }

    function _updateArm(uint32 domain, address contractAddress) internal {
        // CHECKS
        require(contractAddress != address(0), "!contractAddress");
        require(armRegistry[domain] != address(0), "!exists");

        // EFFECTS
        armRegistry[domain] = contractAddress;

        emit UpdatedArm(domain, contractAddress);
    }

    function _checkArrayLength(uint[] memory productsId, uint16[] memory stocks) internal pure {
        // checks if arrays have same length
        uint length = productsId.length;
        require(length == stocks.length, "!stocks");
    }

    function _addWhitelistedSeller(address seller) internal {
        // CHECKS
        sellerWhitelist[seller] = true;

        emit SellerWhitelistAdded(seller);
    }

    function _removeWhitelistedSeller(address seller) internal {
        // CHECKS
        sellerWhitelist[seller] = false;
        
        emit SellerWhitelistRemoved(seller);
    }

    function _getHash(
        uint _productId,
        address _buyer,
        uint _cost,
        uint _chainId,
        uint _nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_productId, _buyer, _cost, _chainId, _nonce));
    }

    function _changeAllowedSigner(address _allowedSigner) internal {
        // CHECKS
        require(_allowedSigner != address(0), "!allowedSigner");

        // EFFECTS
        allowedSigner = _allowedSigner;

        emit ChangedAllowedSigner(_allowedSigner);
    }

}