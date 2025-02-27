// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract OptionContract {
    enum Status {
        Available,
        Sold,
        Expired
    }

    address public owner;
    uint public index;

    struct Option {
        uint index;
        uint asset;
        uint strikePrice;
        uint256 expiryTime;
        address seller;
        address buyer;
        uint256 transactionTime;
        Status status;
    }

    event OptionCreated(address indexed seller, uint asset);
    event OptionExercised(address _buyer, address _seller, uint256 expiryTime);
    event OptionSold(address _seller,address _buyer,uint strikePrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier validAddOption(address _seller, uint256 _expiryTime) {
        require(_seller != address(0), "Invalid seller address");
        require(
            _expiryTime > block.timestamp,
            "Expiry time must be in the future"
        );
        _;
    }
    modifier validateOptionIfSoldOrExpired(
        address _seller,
        uint _index,
        uint256 _expiryTime
    ) {
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].status != Status.Sold &&
                options[_seller][_index].status != Status.Expired,
            "Option is sold or expired"
        );
        require(
            block.timestamp < options[_seller][_index].expiryTime,
            "Option has already passed the expiry  time"
        );
        _;
    }

    modifier validExerciseOption(address _seller, uint _assetPrice) {
        require(_seller != address(0), "Invalid seller address");
        require(_assetPrice > 0, "Asset price needs to be higher");

        _;
    }

    function validateSelling(uint _strikePrice) public returns (bool) {}

    mapping(address => Option[]) public options;

    constructor() {
        owner = msg.sender;
        index = 0;
    }

    function addOption(
        uint _asset,
        uint256 _expiryTime
    ) public onlyOwner validAddOption(msg.sender, _expiryTime) {
        options[msg.sender].push(
            Option({
                index: index,
                asset: _asset,
                strikePrice: 0,
                expiryTime: _expiryTime,
                seller: msg.sender,
                buyer: address(0),
                transactionTime: block.timestamp,
                status: Status.Available
            })
        );
        index += 1;

        emit OptionCreated(msg.sender, _asset);
    }

    function exerciseOption(
        uint _index,
        address _seller,
        uint256 _expiryTime
    ) public validateOptionIfSoldOrExpired(_seller, _index, _expiryTime) {
        options[_seller][_index].status = Status.Available;
        options[_seller][_index].buyer = msg.sender;

        emit OptionExercised(msg.sender, _seller, _expiryTime);
    }

    function updateOption() public {

    }

    function deleteOption() public {}

    function toggleOption() public {}

    function buyOption(
        uint _index,
        address _seller,
        uint _strikePrice,
        uint256 _expiryTime
    ) public validateOptionIfSoldOrExpired(_seller, _index, _expiryTime) {
        options[_seller][_index].status = Status.Sold;

        options[_seller][_index].strikePrice = _strikePrice;




        emit OptionSold(_seller, msg.sender, _strikePrice);


    }
}
