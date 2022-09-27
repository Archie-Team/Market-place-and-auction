//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Migrations {
    address public owner = msg.sender;
    // solhint-disable-next-line
    uint256 public last_completed_migration;
    modifier restricted() {
        require(
            msg.sender == owner,
            "Only Owner"
        );
        _;
    }

    function setCompleted(uint256 completed) public restricted {
        last_completed_migration = completed;
    }
}
