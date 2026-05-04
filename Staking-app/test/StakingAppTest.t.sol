// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingApp.sol";
import "../src/StakingToken.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {

    StakingApp stakingApp;
    StakingToken stakingToken;

    string name_ = "Stakin Token"; 
    string symbol_ = "STK";

    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 1 days;
    uint256 fixedStakingAmount_ = 10;
    uint256 rewarePerPeriod_ = 1 ether;

    address randomUser_ = vm.addr(2);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(
            address(stakingToken),
            owner_,
            stakingPeriod_,
            fixedStakingAmount_,
            rewarePerPeriod_
        );
    }

    function testsStakingTokenCorrectlyDeployed() public view{
        assert(address(stakingToken) != address(0));
    }

    function testsStakingAppCorrectlyDeployed() public view{
        assert(address(stakingApp) != address(0));
    }

    function testChangeStakingPeriodNotOwnerRevert() public {

        uint256 newStakingPeriod = 1;

        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);
    }

    function testChangeStakingPeriodOwnerSuccesful() public {
        vm.startPrank(owner_);
        uint256 newStakingPeriod = 1;

        uint256 stakingPeriodBefore = stakingApp.stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod);
        uint256 stakingPeriodAfter = stakingApp.stakingPeriod();


        assert(stakingPeriodBefore != stakingPeriodAfter);
        vm.stopPrank();
    }

    function testContractReciveEtherCorrectly() public {

        vm.startPrank(owner_);
        vm.deal(owner_, 1 ether);

        uint256 etherValue = 1 ether;

        uint256 balanceBefore_ = address(stakingApp).balance;
        (bool success,) = address(stakingApp).call{value: etherValue}("");
        uint256 balanceAfter_ = address(stakingApp).balance;

        require(success, "Transfer Failed");

        assert(balanceAfter_ - balanceBefore_ == etherValue);

        vm.stopPrank();
    }

    function testDepositTokenIncorrectAmmountRevert() public {
        uint256 tokenAmountDeposit_ = 20;

        vm.expectRevert("Amount not allowed");
        stakingApp.depositTokens(tokenAmountDeposit_);
    }

    function testDepositTokenCorrectly() public {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodBefore = stakingApp.elapsePeriod(randomUser_);

        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodAfter = stakingApp.elapsePeriod(randomUser_);

        assert(userBalanceBefore == 0);
        assert(userBalanceAfter - userBalanceBefore == fixedStakingAmount);

        assert(userElapsePeriodBefore == 0);
        assert(userElapsePeriodAfter == block.timestamp);

        vm.stopPrank();
    }

    function testCanNotDepositTokenMoreThanOnce() public {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodBefore = stakingApp.elapsePeriod(randomUser_);

        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodAfter = stakingApp.elapsePeriod(randomUser_);

        assert(userBalanceBefore == 0);
        assert(userBalanceAfter - userBalanceBefore == fixedStakingAmount);

        assert(userElapsePeriodBefore == 0);
        assert(userElapsePeriodAfter == block.timestamp);

        stakingToken.mint(fixedStakingAmount);
        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);

        vm.expectRevert();
        stakingApp.depositTokens(fixedStakingAmount);
        vm.stopPrank();
    }

    function testWhithdrawZeroTokens() external {

        vm.startPrank(randomUser_);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        stakingApp.withdrawToken();

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);

        assert(userBalanceBefore == userBalanceAfter);
        vm.stopPrank();
    }

    function testWhithdrawTokensCorrectly() public {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);
        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userbalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 stakingTokenBalanceBefore = IERC20(stakingToken).balanceOf(randomUser_);
        stakingApp.withdrawToken();
        uint256 userbalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 stakingTokenBalanceAfter = IERC20(stakingToken).balanceOf(randomUser_);


        assert(userbalanceBefore == fixedStakingAmount);
        assert(userbalanceAfter == 0);
        assert(stakingTokenBalanceAfter + stakingTokenBalanceBefore == stakingTokenBalanceAfter);

        vm.stopPrank();
    }

    function testCanNotClainIfNotStaking() external {
        vm.startPrank(randomUser_);

        vm.expectRevert("Not staking");

        stakingApp.claimrewards();
        vm.stopPrank();
    }

    function testCanNotClaimIfNotElapsedTime() external {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodBefore = stakingApp.elapsePeriod(randomUser_);

        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodAfter = stakingApp.elapsePeriod(randomUser_);

        vm.expectRevert("Need To Wait");
        stakingApp.claimrewards();

        vm.stopPrank();
    }

    function testClaimrewardsNotEther() external {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodBefore = stakingApp.elapsePeriod(randomUser_);

        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodAfter = stakingApp.elapsePeriod(randomUser_);

        vm.warp(block.timestamp + stakingPeriod_);

        vm.expectRevert("Transfer fail");
        stakingApp.claimrewards();

        vm.stopPrank();
    }

    function testClaimrewardsOk() external {
        vm.startPrank(randomUser_);

        uint256 fixedStakingAmount = stakingApp.fixedStakingAmount();

        stakingToken.mint(fixedStakingAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodBefore = stakingApp.elapsePeriod(randomUser_);

        IERC20(stakingToken).approve(address(stakingApp), fixedStakingAmount);
        stakingApp.depositTokens(fixedStakingAmount);

        uint256 userBalanceAfter = stakingApp.userBalance(randomUser_);
        uint256 userElapsePeriodAfter = stakingApp.elapsePeriod(randomUser_);

        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 etherAmount = 1 ether;
        vm.deal(owner_, etherAmount);
        (bool success,) = address(stakingApp).call{value: etherAmount}("");
        require(success, "Test Transfer Fail");
        vm.stopPrank();

        vm.startPrank(randomUser_);
        vm.warp(block.timestamp + stakingPeriod_);
        
        uint256 balanceBefore = address(randomUser_).balance;
        stakingApp.claimrewards();
        uint256 balanceAfter = address(randomUser_).balance;

        assert(balanceAfter - balanceBefore == etherAmount);

        vm.stopPrank();

    }

}