// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract OptionContract {
    enum Status {
        Available,
        Sold,
        Exercised,
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
    mapping(address => uint) public balances;

    constructor() payable {
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
    event Withdraw(address indexed seller, uint amount);
    event Received(address sender, uint amount);

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
            options[_seller][_index].status == Status.Available,
            "Option cannot be updated"
        );
        require(block.timestamp < _expiryTime, "Expiry time has passed");
        require(_asset > 0, "Asset value must be greater than zero");
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
            options[_seller][_index].status == Status.Sold,
            "Option is not sold yet"
        );
        require(
            block.timestamp < options[_seller][_index].expiryTime,
            "Option has expired"
        );

        options[_seller][_index].status = Status.Exercised;

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

    function deleteOption(uint _index) public {
        require(_index < options[msg.sender].length, "Invalid option index");
        require(
            options[msg.sender][_index].status == Status.Available,
            "Cannot delete a sold or expired option"
        );

        uint lastIndex = options[msg.sender].length - 1;
        if (_index != lastIndex) {
            options[msg.sender][_index] = options[msg.sender][lastIndex];
            options[msg.sender][_index].index = _index;
        }

        options[msg.sender].pop();
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

    function buyOption(uint _index, address _seller) public payable {
        require(msg.value > 0, "Must send ETH to buy option");
        require(_index < options[_seller].length, "Invalid option index");
        require(
            options[_seller][_index].status == Status.Available,
            "Option is not available"
        );

        options[_seller][_index].status = Status.Sold;
        options[_seller][_index].buyer = msg.sender;
        options[_seller][_index].strikePrice = msg.value;
        options[_seller][_index].transactionTime = block.timestamp;

        balances[_seller] += msg.value;

        emit OptionSold(_seller, msg.sender, msg.value);
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");

        emit Withdraw(msg.sender, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
