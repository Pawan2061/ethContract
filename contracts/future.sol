// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Future {
    address public owner;
    uint256 public positionIndex;

    enum Status {
        Open,
        Closed
    }
    enum PositionType {
        Long,
        Short
    }

    struct Position {
        uint256 index;
        address user;
        string symbol;
        PositionType positionType;
        uint256 leverage;
        uint256 entryPrice;
        uint256 amount;
        uint256 margin;
        uint256 liquidationPrice;
        Status status;
    }

    Position[] public positions;
    mapping(address => uint256) public walletBalance;
    mapping(address => Position[]) public userPositions;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier validateAddPosition(
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) {
        require(
            _amount > 0 && _leverage > 0 && _entryPrice > 0,
            "Invalid input values"
        );
        _;
    }

    modifier validateDeletePosition(uint256 _index) {
        require(positions[_index].user == msg.sender, "Invalid user attempt");
        require(
            positions[_index].status == Status.Closed,
            "Position is still open"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Deposit funds into the contract
    function depositFunds() public payable {
        require(msg.value > 0, "Deposit must be greater than 0");
        walletBalance[msg.sender] += msg.value;
    }

    /// @notice Withdraw funds from the contract
    function withdrawFunds(uint256 amount) public {
        require(walletBalance[msg.sender] >= amount, "Insufficient funds");
        walletBalance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function addPosition(
        string memory _symbol,
        PositionType _positionType,
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) public validateAddPosition(_amount, _leverage, _entryPrice) {
        uint256 requiredMargin = (_amount * 1e18) / _leverage;
        require(
            walletBalance[msg.sender] >= requiredMargin,
            "Insufficient margin"
        );

        uint256 liquidationPrice;
        if (_positionType == PositionType.Long) {
            liquidationPrice =
                (_entryPrice * (1e18 - (1e18 / _leverage))) /
                1e18;
        } else {
            liquidationPrice =
                (_entryPrice * (1e18 + (1e18 / _leverage))) /
                1e18;
        }

        Position memory newPosition = Position({
            index: positionIndex,
            user: msg.sender,
            symbol: _symbol,
            positionType: _positionType,
            leverage: _leverage,
            entryPrice: _entryPrice,
            amount: _amount,
            margin: requiredMargin,
            liquidationPrice: liquidationPrice,
            status: Status.Open
        });

        positions.push(newPosition);
        userPositions[msg.sender].push(newPosition);

        walletBalance[msg.sender] -= requiredMargin;
        positionIndex++;
    }

    function closePosition(uint256 positionId, uint256 exitPrice) public {
        require(positionId < positions.length, "Invalid position ID");
        Position storage position = positions[positionId];

        require(position.user == msg.sender, "Not position owner");
        require(position.status == Status.Open, "Position already closed");

        uint256 profitOrLoss;
        if (position.positionType == PositionType.Long) {
            profitOrLoss =
                ((exitPrice - position.entryPrice) *
                    position.amount *
                    position.leverage) /
                position.entryPrice;
        } else {
            profitOrLoss =
                ((position.entryPrice - exitPrice) *
                    position.amount *
                    position.leverage) /
                position.entryPrice;
        }

        if (
            (exitPrice > position.entryPrice &&
                position.positionType == PositionType.Long) ||
            (exitPrice < position.entryPrice &&
                position.positionType == PositionType.Short)
        ) {
            walletBalance[msg.sender] += profitOrLoss;
        } else {
            require(
                walletBalance[msg.sender] >= profitOrLoss,
                "Insufficient balance to cover loss"
            );
            walletBalance[msg.sender] -= profitOrLoss;
        }

        position.status = Status.Closed;
    }

    function checkLiquidation(
        uint256 currentPrice
    ) public returns (bool, string memory) {
        for (uint i = 0; i < positions.length; i++) {
            if (positions[i].status == Status.Open) {
                if (
                    (positions[i].positionType == PositionType.Long &&
                        currentPrice <= positions[i].liquidationPrice) ||
                    (positions[i].positionType == PositionType.Short &&
                        currentPrice >= positions[i].liquidationPrice)
                ) {
                    positions[i].status = Status.Closed;
                }
            }
        }
        return (true, "Successfully validated");
    }

    function getPositions() public view returns (Position[] memory) {
        return positions;
    }

    function getUserPositions(
        address _user
    ) public view returns (Position[] memory) {
        return userPositions[_user];
    }

    function getPositionById(
        uint256 _index
    ) public view returns (Position memory) {
        return positions[_index];
    }

    receive() external payable {
        depositFunds();
    }
}
