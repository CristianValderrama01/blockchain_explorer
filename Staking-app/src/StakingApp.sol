// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {

    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewarePerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;

    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    event DepositTokens(address userAddres, uint256 tokenAmountDeposit_);
    event WithdrawToken(address userAddres, uint256 userBalance_);
    event EtherSend(uint256 amount_);

    constructor(address stakingToken_, address owner_, uint256 stakingPeriod_, uint256 fixedStakingAmount_, uint256 rewarePerPeriod_) Ownable(owner_){
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewarePerPeriod = rewarePerPeriod_;
    }

    function depositTokens(uint256 tokenAmountDeposit_) external {
        require(tokenAmountDeposit_ == fixedStakingAmount, "Amount not allowed");
        require(userBalance[msg.sender] == 0, "User Already Deposit");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountDeposit_);
        userBalance[msg.sender] += tokenAmountDeposit_;
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, tokenAmountDeposit_);
    }

    function withdrawToken() external {
        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, userBalance_);

        emit WithdrawToken(msg.sender, userBalance_);
    }

    function claimrewards() external {
        uint256 userBalance_ = userBalance[msg.sender]; 
        uint256 elapsePeriod_ = block.timestamp - elapsePeriod[msg.sender];

        require(userBalance_ == fixedStakingAmount, "Not staking");
        require(elapsePeriod_ >= stakingPeriod, "Need To Wait");

        elapsePeriod[msg.sender] = block.timestamp;

        (bool success,) = msg.sender.call{value: rewarePerPeriod}("");

        require(success, "Transfer fail");
    }

    function feedContract() external payable onlyOwner(){}

    receive() external payable onlyOwner() {
        emit EtherSend(msg.value);
    }



    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner() {
        stakingPeriod = newStakingPeriod_;
        emit ChangeStakingPeriod(newStakingPeriod_);
    }
}