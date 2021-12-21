// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address _address) internal {
        require(
            _address != address(0),
            "The account can't be the zero adderss"
        );
        require(!has(role, _address));

        role.bearer[_address] = true;
    }

    function remove(Role storage role, address _address) internal {
        require(
            _address != address(0),
            "The account can't be the zero adderss"
        );
        require(has(role, _address));

        role.bearer[_address] = false;
    }

    function has(Role storage role, address _address)
        internal
        view
        returns (bool)
    {
        require(
            _address != address(0),
            "The account can't be the zero adderss"
        );

        return role.bearer[_address];
    }
}
