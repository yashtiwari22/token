// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is Ownable {
    IERC20 public usdcToken; // The USDC token contract address
    uint256 public lockDuration; // Lock duration in seconds (180 days in this case)

    struct StakingRecord {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    mapping(address => StakingRecord[]) public stakingHistory;

    constructor(address _usdcTokenAddress) {
        usdcToken = IERC20(_usdcTokenAddress);
        lockDuration = 180 days;
    }

    event Staked(address indexed user, uint256 amount, uint256 unlockTimestamp);
    event Unstaked(address indexed user, uint256 amount);

    // Stake USDC tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        uint256 unlockTimestamp = block.timestamp + lockDuration;
        stakingHistory[msg.sender].push(StakingRecord(amount, unlockTimestamp));

        emit Staked(msg.sender, amount, unlockTimestamp);
    }

    // Unstake USDC tokens
    function unstake(uint256 index) external {
        require(index < stakingHistory[msg.sender].length, "Invalid index");
        StakingRecord storage record = stakingHistory[msg.sender][index];
        require(
            block.timestamp >= record.unlockTimestamp,
            "Tokens are still locked"
        );

        uint256 amountToUnstake = record.amount;
        stakingHistory[msg.sender][index] = stakingHistory[msg.sender][
            stakingHistory[msg.sender].length - 1
        ];
        stakingHistory[msg.sender].pop();

        require(
            usdcToken.transfer(msg.sender, amountToUnstake),
            "Transfer failed"
        );

        emit Unstaked(msg.sender, amountToUnstake);
    }

    // Get the number of staking records for a user
    function getStakingRecordCount(
        address user
    ) external view returns (uint256) {
        return stakingHistory[user].length;
    }

    // Get a specific staking record for a user
    function getStakingRecord(
        address user,
        uint256 index
    ) external view returns (uint256 amount, uint256 unlockTimestamp) {
        require(index < stakingHistory[user].length, "Invalid index");
        StakingRecord storage record = stakingHistory[user][index];
        return (record.amount, record.unlockTimestamp);
    }
}
