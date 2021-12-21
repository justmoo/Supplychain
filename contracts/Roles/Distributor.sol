// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";

contract Distributor is Ownable {
    using Roles for Roles.Role;

    Roles.Role private distributors;

    // events
    event addedDistributor(address indexed _address);
    event renouncedDistributor(address indexed _address);

    constructor() {
        addDistributor(owner());
    }

    modifier onlyDistributor() {
        require(isDistributor(_msgSender()), "must be distributor");
        _;
    }

    function isDistributor(address _address) internal view returns (bool) {
        return (distributors.has(_address));
    }

    function addDistributor(address _address) public onlyOwner {
        distributors.add(_address);
        emit addedDistributor(_address);
    }

    function renounceDistributor() public onlyDistributor {
        distributors.remove(_msgSender());
        emit renouncedDistributor(_msgSender());
    }
}
