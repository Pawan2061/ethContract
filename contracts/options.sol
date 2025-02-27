// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract OptionContract {
    enum Status {
        OnTransaction,
        Sold,
        NotBought
    }

    address public owner;
    
    struct Option {
        uint asset;
        uint strikePrice;
        uint256 expiryTime;
        address seller;
        address buyer;
        uint256 transactionTime;
        Status status;
    }

    event OptionTraded(address indexed seller, address indexed buyer, uint strikePrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validOption(address _seller, address _buyer, uint256 _expiryTime) {
        require(_seller != address(0), "Invalid seller address");
        require(_buyer != address(0), "Invalid buyer address");
        require(_expiryTime > block.timestamp, "Expiry time must be in the future");
        _;
    }

    mapping(address => Option[]) public options;

    constructor() {
        owner = msg.sender;
    }

    function addOption(
        uint _asset,
        uint _strikePrice,
        uint256 _expiryTime,
        address _seller,
        address _buyer
    ) public onlyOwner validOption(_seller, _buyer, _expiryTime) {
        options[_seller].push(Option({
            asset: _asset,
            strikePrice: _strikePrice,
            expiryTime: _expiryTime,
            seller: _seller,
            buyer: _buyer,
            transactionTime: block.timestamp,
            status: Status.OnTransaction
        }));

        emit OptionTraded(_seller, _buyer, _strikePrice);
    }



    function updateOption() public {}

    function deleteOption() public {}

    function toggleOption() public {}
}
