pragma solidity ^0.8.28;

contract Lock {
    address public owner;
    uint public index;

    enum Status {
        Open,
        Closed
    }
    enum PositionType {
        Long,
        Short
    }
    struct Position {
        address user;
        string symbol;
        PositionType positionType;
        uint256 leverage;
        uint256 entryPrice;
        uint256 amount;
        uint256 liquidationPrice;
        Status status;
    }

    mapping(address => uint256) public walletBalance;
    mapping(address => Position[]) public userPositions;
    modifier validateAddPosition(
        address _seller,
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) {
        require(_seller != address(0), "Invalid seller address");

        require(
            _amount > 0 && _leverage > 0 && _entryPrice > 0,
            "Invalid amount size,should be greater than zero"
        );
        _;
    }

    function addPosition(
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) public validateAddPosition(msg.sender, _amount, _leverage, _entryPrice) {
        require(
            walletBalance[msg.sender] >= (_amount / _leverage),
            "Insufficient Margin"
        );
    }
}
