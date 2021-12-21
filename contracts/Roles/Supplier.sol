// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";

contract Supplier is Ownable {
    using Roles for Roles.Role;

    Roles.Role private suppliers;

    // events
    event addedSupplier(address indexed _address);
    event renouncedSupplier(address indexed _address);

    constructor() {
        addSupplier(owner());
    }

    modifier onlySupplier() {
        require(isSupplier(_msgSender()), "must be supplier");
        _;
    }

    function isSupplier(address _address) internal view returns (bool) {
        return (suppliers.has(_address));
    }

    function addSupplier(address _address) public onlyOwner {
        suppliers.add(_address);
        emit addedSupplier(_address);
    }

    function renounceSupplier() public onlySupplier {
        suppliers.remove(_msgSender());
        emit renouncedSupplier(_msgSender());
    }
}
