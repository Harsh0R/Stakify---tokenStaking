// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public rewardToken;

    uint256 public constant REWARD_RATE = 10 * 1e18;
    uint256 public totalStakedTokens;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public stakedBalances;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStakedTokens == 0) {
            return rewardPerTokenStored;
        }
        uint256 totalTime = block.timestamp.sub(lastUpdateTime);
        uint256 reward = totalTime.mul(REWARD_RATE).div(totalStakedTokens);
        return rewardPerTokenStored.add(reward);
    }

    function earned(address account) public view returns (uint256) {
        return stakedBalances[account]
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function stake() external payable nonReentrant updateReward(msg.sender) {
        uint256 amount = msg.value;
        require(amount > 0, "Amount must be greater than 0");

        totalStakedTokens = totalStakedTokens.add(amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].add(amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= stakedBalances[msg.sender], "Insufficient staked balance");

        totalStakedTokens = totalStakedTokens.sub(amount);
        stakedBalances[msg.sender] = stakedBalances[msg.sender].sub(amount);

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        rewards[msg.sender] = 0;
        bool success = rewardToken.transfer(msg.sender, reward);
        require(success, "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }
}
