// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
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
        uint256 expiryDate;
        address seller;
        address buyer;
        uint256 transactionTime;
        Status status;
    }

    mapping(address => Option[]) public options;

    constructor() {
        owner = msg.sender;
    }

    function addOption() public {}
    function updateOption() public {}
    function deleteOption() public {}
    function toggleOption() public {}
}
