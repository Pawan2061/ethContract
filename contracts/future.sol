// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Future {
    address public owner;
    uint public positionIndex;

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

    modifier validateDeleteOption(uint256 _index) {
        require(positions[_index].user == msg.sender, "Invalid user attempt");
        _;
        require(
            positions[_index].status == Status.Closed,
            "Position already closed"
        );
    }
    constructor() {
        owner = msg.sender;
    }

    function addPosition(
        string memory _symbol,
        PositionType _positionType,
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) public validateAddPosition(_amount, _leverage, _entryPrice) {
        uint256 requiredMargin = _amount / _leverage;
        require(
            walletBalance[msg.sender] >= requiredMargin,
            "Insufficient Margin"
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

        positionIndex++;
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
        uint _index
    ) public view returns (Position memory) {
        return positions[_index];
    }
    function deletePosition() public {}

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
    function liquidate() public {}
    function closePosition(uint256 positionId, uint256 exitPrice) public {
        require(positionId < positions.length, "Invalid position ID");
        Position storage position = positions[positionId];

        require(position.user == msg.sender, "Not position owner");
        require(position.status == Status.Open, "Position already closed");

        uint256 profitOrLoss;
        if (position.positionType == PositionType.Long) {
            profitOrLoss = (exitPrice > position.entryPrice)
                ? (exitPrice - position.entryPrice) * position.amount
                : (position.entryPrice - exitPrice) * position.amount;
        } else {
            profitOrLoss = (position.entryPrice > exitPrice)
                ? (position.entryPrice - exitPrice) * position.amount
                : (exitPrice - position.entryPrice) * position.amount;
        }

        if (
            exitPrice >= position.entryPrice &&
            position.positionType == PositionType.Long
        ) {
            walletBalance[msg.sender] += profitOrLoss;
        } else if (
            exitPrice < position.entryPrice &&
            position.positionType == PositionType.Long
        ) {
            require(
                walletBalance[msg.sender] >= profitOrLoss,
                "Insufficient balance"
            );
            walletBalance[msg.sender] -= profitOrLoss;
        } else if (
            exitPrice <= position.entryPrice &&
            position.positionType == PositionType.Short
        ) {
            walletBalance[msg.sender] += profitOrLoss;
        } else {
            require(
                walletBalance[msg.sender] >= profitOrLoss,
                "Insufficient balance"
            );
            walletBalance[msg.sender] -= profitOrLoss;
        }

        position.status = Status.Closed;
    }
}
