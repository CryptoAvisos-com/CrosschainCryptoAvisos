// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./Base.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
    
    function _checkOwnership(uint productId) internal view {
        require(productId != 0, "!productId");
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "!exist");
        require(owner() == msg.sender || (sellerWhitelist[msg.sender] && product.seller == msg.sender), "!whitelisted");
    }

    function _setFee(uint newFee) internal {
        //Set fee. Example: 10e18 = 10%
        require(newFee <= 100e18, "!fee");
        uint previousFee = fee;
        fee = newFee;
        emit FeeSetted(previousFee, newFee);
    }

    function _payProduct(uint productId, uint shippingCost, bytes memory signedMessage) internal {
        require(executed[signedMessage] == false, "!signedMessage");
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "!exist");
        require(product.enabled, "!enabled");
        require(product.stock != 0, "!stock");

        // verifing signature
        bytes32 _hash = _getHash(productId, msg.sender, shippingCost, block.chainid, nonce);
        bytes32 ethSignedHash = _hash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signedMessage);
        require(allowedSigner == signer, "!allowedSigner");

        uint price = product.price + shippingCost;

        if (product.token == address(0)) {
            //Pay with ether (or native coin)
            require(msg.value == price, "!msg.value");
        }else{
            //Pay with token
            IERC20(product.token).transferFrom(msg.sender, address(this), price);
        }

        uint toFee = product.price * fee / 100e18;

        //Create ticket
        uint ticketId = uint(keccak256(abi.encode(productId, msg.sender, block.number, product.stock)));
        productTicketsMapping[ticketId] = Ticket(productId, Status.WAITING, payable(msg.sender), product.token, toFee, product.price, shippingCost);
        ticketsIds.push(ticketId);

        product.stock -= 1;
        executed[signedMessage] = true;
        nonce++;
        productMapping[productId] = product;
        emit ProductPaid(productId, ticketId);
    }

    function _submitProduct(uint productId, address payable seller, uint price, address token, uint16 stock, bool enabled) internal {
        require(productId != 0, "!productId");
        require(price != 0, "!price");
        require(seller != address(0), "!seller");
        require(stock != 0, "!stock");
        require(productMapping[productId].seller == address(0), "alreadyExist");
        require(owner() == msg.sender || seller == msg.sender, "!whitelisted");
        productMapping[productId] = Product(price, seller, token, enabled, stock);
        productsIds.push(productId);
        emit ProductSubmitted(productId);
    }

    function _updateProduct(uint productId, address payable seller, uint price, address token, uint16 stock, bool enabled) internal {
        require(price != 0, "!price");
        require(seller != address(0), "!seller");
        productMapping[productId] = Product(price, seller, token, enabled, stock);
        emit ProductUpdated(productId);
    }

    function _addStock(uint productId, uint16 stockToAdd) internal {
        Product memory product = productMapping[productId];
        require(stockToAdd != 0, "!stockToAdd");
        product.stock += stockToAdd;
        productMapping[productId] = product;
        emit StockAdded(productId, stockToAdd);
    }

    function _removeStock(uint productId, uint16 stockToRemove) internal {
        Product memory product = productMapping[productId];
        require(product.stock >= stockToRemove, "!stockToRemove");
        product.stock -= stockToRemove;
        productMapping[productId] = product;
        emit StockRemoved(productId, stockToRemove);
    }

    function _switchEnable(uint productId, bool isEnabled) internal {
        Product memory product = productMapping[productId];
        product.enabled = isEnabled;
        productMapping[productId] = product;
        emit SwitchChanged(productId, isEnabled);
    }

    function _checkArrayLength(uint[] memory productsId, uint16[] memory stocks) internal pure {
        // checks if arrays have same length
        uint length = productsId.length;
        require(length == stocks.length, "!stocks");
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
        require(_allowedSigner != address(0), "!allowedSigner");
        allowedSigner = _allowedSigner;
        emit ChangedAllowedSigner(_allowedSigner);
    }

}