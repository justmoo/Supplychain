// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";

contract Consumer is Ownable {
    using Roles for Roles.Role;

    Roles.Role private consumers;

    // events
    event addedConsumer(address indexed _address);
    event renouncedConsumer(address indexed _address);

    constructor() {
        addConsumer(owner());
    }

    modifier onlyConsumer() {
        require(isConsumer(_msgSender()), "must be consumer");
        _;
    }

    function isConsumer(address _address) internal view returns (bool) {
        return (consumers.has(_address));
    }

    function addConsumer(address _address) public onlyOwner {
        consumers.add(_address);
        emit addedConsumer(_address);
    }

    function renounceConsumer() public onlyConsumer {
        consumers.remove(_msgSender());
        emit renouncedConsumer(_msgSender());
    }
}
