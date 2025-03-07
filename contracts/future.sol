pragma solidity ^0.8.28;

contract Future {
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
        uint256 margin;
        uint256 liquidationPrice;
        Status status;
    }
    Position[] positions;

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
        string memory _symbol,
        PositionType _positionType,
        uint256 _amount,
        uint256 _leverage,
        uint256 _entryPrice
    ) public validateAddPosition(msg.sender, _amount, _leverage, _entryPrice) {
        require(
            walletBalance[msg.sender] >= (_amount / _leverage),
            "Insufficient Margin"
        );

        uint256 liquidationPrice;
        if (_positionType == PositionType.Long) {
            liquidationPrice = _entryPrice * (1 - (1 / _leverage));
        } else {
            liquidationPrice = _entryPrice * (1 + (1 / _leverage));
        }

        userPositions[msg.sender].push(
            Position({
                user: msg.sender,
                symbol: _symbol,
                positionType: _positionType,
                leverage: _leverage,
                entryPrice: _entryPrice,
                amount: _amount,
                liquidationPrice: liquidationPrice,
                status: Status.Open,
                margin: _amount / _leverage
            })
        );
    }

    function getPositions() public view returns (Position[] memory) {
        require(positions.length > 0, "Total positions is less than 0");

        return positions;
    }
    function getUserPositions(
        address _user
    ) public view returns (Position[] memory) {
        require(
            userPositions[_user].length > 0,
            "user doesnt have any positions"
        );

        return userPositions[_user];
    }
}

function closePosition() {}
function checkLiquidation() {}
