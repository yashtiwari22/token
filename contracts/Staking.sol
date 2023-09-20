// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingPool {
    address public admin;
    uint256 public poolIdCounter;

    struct Pool {
        uint256 timePeriod;
        address rewardToken;
        uint256 rewardPercentPerStakedTokenPerSec;
    }

    struct UserStake {
        uint256 amount;
        uint256 lastWithdrawTimestamp;
        uint256 rewardWithdrawTillNow;
        uint256 firstStakeTime;
    }

    mapping(uint256 => Pool) public pools;
    mapping(address => mapping(uint256 => UserStake)) public userStakes;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function createStakingPool(
        uint256 _timePeriod,
        address _rewardToken,
        uint256 _rewardPercent
    ) external onlyAdmin {
        poolIdCounter++;
        pools[poolIdCounter] = Pool(_timePeriod, _rewardToken, _rewardPercent);
    }

    function stake(uint256 _poolId, uint256 _amount) external {
        require(_poolId > 0 && _poolId <= poolIdCounter, "Invalid pool ID");
        require(_amount > 0, "Amount must be greater than 0");

        UserStake storage userStake = userStakes[msg.sender][_poolId];
        Pool storage pool = pools[_poolId];

        require(
            userStake.firstStakeTime == 0 ||
                block.timestamp >= userStake.firstStakeTime + pool.timePeriod,
            "Time period not passed"
        );

        // Transfer tokens from the user to this contract for staking
        require(
            ERC20(pool.rewardToken).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Token transfer failed"
        );

        if (userStake.firstStakeTime == 0) {
            userStake.firstStakeTime = block.timestamp;
        }

        userStake.amount += _amount;
        userStake.lastWithdrawTimestamp = block.timestamp;
    }

    function unstake(uint256 _poolId, uint256 _amount) external {
        require(_poolId > 0 && _poolId <= poolIdCounter, "Invalid pool ID");
        require(_amount > 0, "Amount must be greater than 0");

        UserStake storage userStake = userStakes[msg.sender][_poolId];
        Pool storage pool = pools[_poolId];

        require(userStake.amount >= _amount, "Insufficient staked amount");

        uint256 currentTime = block.timestamp;
        require(
            currentTime >= userStake.firstStakeTime + pool.timePeriod,
            "Time period not passed"
        );

        withdrawReward(_poolId);

        // Reduce the staked amount
        userStake.amount -= _amount;

        // If the staked amount becomes zero, reset the firstStakeTime
        if (userStake.amount == 0) {
            userStake.firstStakeTime = 0;
        }

        // Update the lastWithdrawTimestamp
        userStake.lastWithdrawTimestamp = currentTime;

        // Transfer the staked tokens back to the user
        require(
            ERC20(pool.rewardToken).transfer(msg.sender, _amount),
            "Staked token transfer failed"
        );
    }

    function withdrawReward(uint256 _poolId) public returns (uint256) {
        require(_poolId > 0 && _poolId <= poolIdCounter, "Invalid pool ID");

        UserStake storage userStake = userStakes[msg.sender][_poolId];
        Pool storage pool = pools[_poolId];

        require(userStake.amount > 0, "No stake in the pool");

        uint256 currentTime = block.timestamp;
        uint256 stakedTime = currentTime - userStake.lastWithdrawTimestamp;
        uint256 stakedTokens = (userStake.amount *
            stakedTime *
            pool.rewardPercentPerStakedTokenPerSec) / 100;
        uint256 reward = stakedTokens;

        userStake.rewardWithdrawTillNow += reward;
        userStake.lastWithdrawTimestamp = currentTime;
        require(
            ERC20(pool.rewardToken).transfer(msg.sender, reward),
            "Reward transfer failed"
        );
        return reward;
    }

    function getPendingReward(uint256 _poolId) external view returns (uint256) {
        require(_poolId > 0 && _poolId <= poolIdCounter, "Invalid pool ID");

        UserStake storage userStake = userStakes[msg.sender][_poolId];
        Pool storage pool = pools[_poolId];

        uint256 currentTime = block.timestamp;
        uint256 stakedTime = currentTime - userStake.lastWithdrawTimestamp;
        uint256 stakedTokens = (userStake.amount *
            stakedTime *
            pool.rewardPercentPerStakedTokenPerSec) / 100;
        uint256 reward = stakedTokens;

        return reward;
    }
}
