// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";

contract Trader is Ownable {
    using Roles for Roles.Role;

    Roles.Role private traders;

    // events
    event addedTrader(address indexed _address);
    event renouncedTrader(address indexed _address);

    constructor() {
        addTrader(owner());
    }

    modifier onlyTrader() {
        require(isTrader(_msgSender()), "must be Trader");
        _;
    }

    function isTrader(address _address) internal view returns (bool) {
        return (traders.has(_address));
    }

    function addTrader(address _address) public onlyOwner {
        traders.add(_address);
        emit addedTrader(_address);
    }

    function renounceTrader() public onlyTrader {
        traders.remove(_msgSender());
        emit renouncedTrader(_msgSender());
    }
}
