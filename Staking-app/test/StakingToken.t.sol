// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingTokenTest is Test{

    StakingToken stakingToken;
    string name_ = "Stakin Token"; 
    string symbol_ = "STK";
    address randomUser_ = vm.addr(1);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
    }

    function testMintCorrectly() public {

        vm.startPrank(randomUser_);
        uint256 amountBefore_ = IERC20(address(stakingToken)).balanceOf(randomUser_);

        uint256 amount_ = 1 ether;
        stakingToken.mint(amount_);

        uint256 amountAfter_ = IERC20(address(stakingToken)).balanceOf(randomUser_);

        vm.stopPrank();

        assert(amountAfter_ - amountBefore_ == amount_);
    }

}