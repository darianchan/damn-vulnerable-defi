// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "hardhat/console.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    mapping(address => uint256) private balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        
        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance; // = 1000 eth to start

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}(); // will send whatever amount you want to flashloan to you

        if (address(this).balance < balanceBefore) // only requirement is that this contracts balance is >= than it's inital balance
            revert RepayFailed();
    }
}

/*
    - take out flash loan for 1000 eth
    - during flash loan execution, deposit the 1000 eth into the contract (this will satisfy the flash loan requirement)
    - then after the flashloan is paid back, call the withdraw() function to withdraw the 1000 eth

*/
