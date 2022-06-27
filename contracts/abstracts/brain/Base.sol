// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

abstract contract Base {
    
    mapping(uint => Product) public productMapping; // productId in CA platform => Product
    mapping(uint => Ticket) public productTicketsMapping; // uint(keccak256(productId, buyer, blockNumber, product.stock)) => Ticket
    mapping(address => uint) public claimableFee;
    mapping(address => uint) public claimableShippingCost;
    mapping(bytes => bool) public executed;
    mapping(address => bool) public sellerWhitelist;
    mapping(uint32 => address) public armRegistry; // domain => contract address
    mapping(uint32 => mapping(address => address)) public tokenAddresses; // domain => settlement token in main chain => settlement token in foreign chain
    uint[] public productsIds;
    uint[] public ticketsIds;

    uint public fee;
    uint public lastUnlockTimeFee;
    uint public lastFeeToSet;
    uint public nonce;
    uint32 public brainDomain; // this contract domain

    address public allowedSigner;

    event ProductSubmitted(uint productId);
    event ProductPaid(uint productId, uint ticketId, uint shippingCost, bool xcall);
    event PayReleased(uint productId, uint tickerId, bool xcall);
    event ProductUpdated(uint productId);
    event ProductRefunded(uint productId, uint ticketId, bool xcall);
    event SwitchChanged(uint productId, bool isEnabled);
    event FeeSetted(uint previousFee, uint newFee);
    event ShippingCostClaimed(address receiver, address token, uint quantity);
    event FeesClaimed(address receiver, address token, uint quantity);
    event PreparedFee(uint fee, uint unlockTime);
    event StockAdded(uint productId, uint16 stockAdded);
    event StockRemoved(uint productId, uint16 stockRemoved);
    event SellerWhitelistAdded(address seller);
    event SellerWhitelistRemoved(address seller);
    event ChangedAllowedSigner(address newAllowedSigner);
    event AddedArm(uint32 domain, address contractAddress);
    event UpdatedArm(uint32 domain, address contractAddress);

    struct Product {
        uint price; // in WEI
        address seller;
        address token; // contract address or 0x00 if it's native coin
        bool enabled;
        uint32 outputPaymentDomain; // domain for payment to buyer
        uint16 stock;
    }

    struct Ticket {
        uint productId;
        Status status;
        address buyer;
        address tokenPaid; // holds contract address or 0x00 if it's native coin used in payment
        uint feeCharged; // holds charged fee, in case admin need to refund and fee has changed between pay and refund time
        uint pricePaid; // holds price paid at moment of payment (without fee)
        uint shippingCost; // holds shipping cost (In WEI)
        uint32 inputPaymentDomain; // domain choosed by buyer
    }

    enum Status {
        WAITING,
        SOLD,
        REFUNDED
    }

}