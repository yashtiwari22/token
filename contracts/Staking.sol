// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CGate.sol";

error Staking__TransferFailed();
error Withdraw__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking is ReentrancyGuard {
    CGate s_stakingToken;
    IERC20 public s_rewardToken;

    uint256 public REWARD_RATE = 30;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdateTime;

    uint256 public s_planDuration;
    uint256 public s_planExpired;

    // Referral bonus percentages
    uint256 public constant REGULAR_REFERRAL_BONUS_PERCENT = 3;
    uint256 public constant SPECIAL_REFERRAL_BONUS_PERCENT = 20;

    /** @dev Mapping from address to the amount the user has staked */
    mapping(address => uint256) public s_balances;

    /** @dev Mapping from address to the amount the user has been rewarded */
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    /** @dev Mapping from address to the rewards claimable for user */
    mapping(address => uint256) public s_rewards;

    mapping(address => uint256) public endTs;

    // Add referral tracking variables
    mapping(address => address) public s_referrals; // Mapping from user to their referrer
    mapping(address => uint256) public s_referralBonuses; // Mapping from user to their referral bonus

    modifier updateReward(address account) {
        // how much reward per token?
        // get last timestamp

        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;

        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    constructor(
        address stakingToken,
        address rewardToken,
        uint256 planDuration
    ) {
        s_stakingToken = CGate(stakingToken);
        s_rewardToken = IERC20(rewardToken);
        s_planDuration = planDuration;
        s_planExpired = block.timestamp + planDuration;
    }

    function setRewardRate(uint256 _rate) external {
        REWARD_RATE = _rate;
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        // how much they were paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 _earned = ((currentBalance *
            (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;

        return _earned;
    }

    /** @dev Basis of how long it's been during the most recent snapshot/block */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        } else {
            return
                s_rewardPerTokenStored +
                (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) /
                    s_totalSupply);
        }
    }

    function stake(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
        /** @notice Be mindful of reentrancy attack here */
        require(block.timestamp < s_planExpired, "Plan Expired");
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;
        //emit event
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        endTs[msg.sender] = block.timestamp + s_planDuration;
        // require(success, "Failed"); Save gas fees here
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) {
        s_balances[msg.sender] -= amount;
        s_totalSupply -= amount;
        // emit event
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Withdraw__TransferFailed();
        }
    }

    function claimReward(address referrer) external updateReward(msg.sender) {
        require(
            endTs[msg.sender] < block.timestamp,
            "Stake Time is not over yet"
        );
        uint256 reward = s_rewards[msg.sender];
        // Calculate regular referral bonus
        uint256 regularReferralBonus = (reward *
            REGULAR_REFERRAL_BONUS_PERCENT) / 100;
        if (
            referrer != address(0) &&
            referrer != msg.sender &&
            s_referrals[msg.sender] == address(0)
        ) {
            // Assign referrer and bonus for the first-time referral
            s_referrals[msg.sender] = referrer;
            s_referralBonuses[msg.sender] = regularReferralBonus;
        }

        // Calculate special referral bonus for selected addresses (e.g., influencers)
        if (s_referralBonuses[msg.sender] == 0) {
            uint256 specialReferralBonus = (reward *
                SPECIAL_REFERRAL_BONUS_PERCENT) / 100;
            s_referralBonuses[msg.sender] = specialReferralBonus;
        }
        // Deduct the referral bonuses and source USDC from the staking reward pool
        uint256 totalBonus = s_referralBonuses[msg.sender];
        s_referralBonuses[msg.sender] = 0;

        // Ensure there are enough rewards in the pool to distribute
        require(
            reward >= totalBonus,
            "Not enough rewards in the pool for referral bonuses"
        );

        reward -= totalBonus;
        bool success = s_rewardToken.transfer(msg.sender, reward);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    // Getter for UI
    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }
}
