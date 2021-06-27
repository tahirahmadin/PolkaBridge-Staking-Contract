pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Staking is ERC20, Ownable {
    using SafeMath for uint256;

    string public tokenName = "PBR";
    address public contractAddress;
    address[] public stakers;

    uint256 private stakeStartTime;
    uint256 private todayStakeEndTime = 0;

    uint256 private availableStakeRewards;

    uint256 private blocksPerDay = 8000;

    mapping(address => uint256) stakingBalance; // staking balance of each user
    mapping(address => uint256) stakingTime; // staking time of each user
    mapping(address => bool) hasStaked;
    mapping(address => bool) isStaking;
    mapping(address => uint256) public balanceOfUser;
    mapping(address => uint256) public userBlocks;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    constructor() public {
        contractAddress = msg.sender;
        availableStakeRewards = 360000;
        stakeStartTime = block.timestamp;
    }

    //updating staking reward per month:  to be finalized
    function updateStakingReward() public onlyOwner {
        availableStakeRewards = 360000;
    }

    //Tranfer tokens to user
    function transferTo(address _to, uint256 _amount) public returns (bool) {
        require(balanceOfUser[msg.sender] >= _amount);
        balanceOfUser[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    //Transfer tokens to smart contract
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        require(_amount <= balanceOfUser[_from]);
        balanceOfUser[_from] -= _amount;
        balanceOfUser[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    //staking
    function stakeTokens(uint256 _amount) public {
        //Transfer funds to smart contract of staking
        require(_amount > 0, "Amount should be greater than 0.");
        transferFrom(msg.sender, address(this), _amount);

        //update staking balance of user
        stakingBalance[msg.sender] += _amount;

        //Add user to stakers array only if not added.
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        if (!isStaking[msg.sender]) {
            stakingTime[msg.sender] = block.timestamp;
        }
        //update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    //unstaking
    function unStakeToken(uint256 _amount) public {
        //Fetch staking balance
        uint256 balance = stakingBalance[msg.sender];

        //require amount greater than 0
        require(balance > 0, "Staking balance should be greater than 0.");

        require(
            _amount <= balance,
            "Staking balance should be greater than 0."
        );

        //Removing the unstake tokens
        stakingBalance[msg.sender] -= _amount;

        //removing the status
        if (stakingBalance[msg.sender] == 0) {
            isStaking[msg.sender] = false;
        }
        distributeReward(msg.sender, _amount);
    }

    // Issuing token
    function distributeReward(address _address, uint256 _amount) private {
        uint256 rewads = calculateReward(_address);

        //Transfering the rewards and token to user
        transferTo(msg.sender, _amount + rewads);
        availableStakeRewards = 0;
    }

    // Calculation of rewads token
    function calculateReward(address _address) public view returns (uint256) {
        uint256 userStakingBlock =
            (block.timestamp - stakingTime[_address]) / (24 * 60 * 60);
        uint256 reward = (blocksPerDay * userStakingBlock * 3) / 2;

        return reward;
    }
}
