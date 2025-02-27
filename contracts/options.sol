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

    mapping(address => Option[]) public options;

    constructor() {
        owner = msg.sender;
        index = 0;
    }

    event OptionCreated(address indexed seller, uint asset);
    event OptionExercised(
        address indexed buyer,
        address indexed seller,
        uint index
    );
    event OptionSold(
        address indexed seller,
        address indexed buyer,
        uint strikePrice
    );
    event OptionUpdated(address indexed seller, uint asset, uint256 expiryTime);

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

    modifier validateUpdateOption(
        uint _index,
        uint256 _expiryTime,
        uint _asset,
        address _seller
    ) {
        require(_seller != address(0), "Invalid seller address");
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].status != Status.Sold &&
                options[_seller][_index].status != Status.Expired,
            "This option cannot be updated"
        );
        require(block.timestamp < _expiryTime, "Expiry time has passed");
        require(_asset > 0, "Asset value must be greater than zero");
        _;
    }

    modifier validateOptionIfSoldOrExpired(address _seller, uint _index) {
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].status == Status.Available,
            "Option is already sold or expired"
        );
        require(
            block.timestamp < options[_seller][_index].expiryTime,
            "Option has already expired"
        );
        _;
    }

    function addOption(
        uint _asset,
        uint256 _expiryTime
    ) public validAddOption(msg.sender, _expiryTime) {
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
        index++;

        emit OptionCreated(msg.sender, _asset);
    }

    function exerciseOption(uint _index, address _seller) public {
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].buyer == msg.sender,
            "Only buyer can exercise this option"
        );
        require(
            block.timestamp < options[_seller][_index].expiryTime,
            "Option has expired"
        );

        options[_seller][_index].status = Status.Expired;

        emit OptionExercised(msg.sender, _seller, _index);
    }

    function updateOption(
        uint _index,
        uint _asset,
        uint256 _expiryTime
    ) public validateUpdateOption(_index, _expiryTime, _asset, msg.sender) {
        options[msg.sender][_index].asset = _asset;
        options[msg.sender][_index].expiryTime = _expiryTime;

        emit OptionUpdated(msg.sender, _asset, _expiryTime);
    }

    function deleteOption(address _seller, uint _index) public {
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].status == Status.Available,
            "Cannot delete a sold or expired option"
        );

        // Swap with last element and pop to maintain array integrity
        uint lastIndex = options[_seller].length - 1;
        options[_seller][_index] = options[_seller][lastIndex];
        options[_seller].pop();
    }

    function getOptions(address _seller) public view returns (Option[] memory) {
        return options[_seller];
    }

    function getOption(
        uint _index,
        address _seller
    ) public view returns (Option memory) {
        require(_index < options[_seller].length, "Invalid option index");
        return options[_seller][_index];
    }

    function buyOption(
        uint _index,
        address _seller,
        uint _strikePrice
    ) public validateOptionIfSoldOrExpired(_seller, _index) {
        require(_strikePrice > 0, "Strike price must be greater than zero");

        options[_seller][_index].status = Status.Sold;
        options[_seller][_index].buyer = msg.sender;
        options[_seller][_index].strikePrice = _strikePrice;
        options[_seller][_index].transactionTime = block.timestamp;

        emit OptionSold(_seller, msg.sender, _strikePrice);
    }
}
