pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VotingResultNFT} from "./VotingResultNFT.sol";

contract VegaVoting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable VV_TOKEN;
    VotingResultNFT public immutable RESULT_NFT;

    struct Stake {
        uint256 amount;
        uint256 expiry;
        uint8 multiplier;
    }

    struct Voting {
        bytes32 id;
        uint256 deadline;
        uint256 votingPowerThreshold;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
    }

    mapping(address => Stake[]) public stakes;
    mapping(bytes32 => Voting) public votings;
    mapping(bytes32 => mapping(address => bool)) public hasVoted;

    constructor(address vvToken, address resultNft) Ownable(msg.sender) {
        VV_TOKEN = IERC20(vvToken);
        RESULT_NFT = VotingResultNFT(resultNft);
    }

    function stake(uint256 amount, uint256 duration, uint8 multiplier) external whenNotPaused {
        require(multiplier >= 1 && multiplier <= 4);
        require(amount > 0);

        VV_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        stakes[msg.sender].push(
            Stake({
                amount: amount,
                expiry: block.timestamp + duration,
                multiplier: multiplier
            })
        );
    }

    function votingPower(address user) public view returns (uint256 total) {
        Stake[] memory userStakes = stakes[user];

        for (uint256 i = 0; i < userStakes.length; i++) {
            if (block.timestamp < userStakes[i].expiry) {
                uint256 remain = userStakes[i].expiry - block.timestamp;
                total += userStakes[i].amount * remain * remain;
            }
        }
    }

    function createVoting(
        bytes32 id,
        uint256 deadline,
        uint256 threshold,
        string calldata description
    ) external onlyOwner {
        require(votings[id].deadline == 0);
        require(deadline > block.timestamp);

        votings[id] = Voting({
            id: id,
            deadline: deadline,
            votingPowerThreshold: threshold,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            finalized: false
        });
    }

    function vote(bytes32 id, bool support) external whenNotPaused {
        Voting storage v = votings[id];

        require(block.timestamp < v.deadline);
        require(!v.finalized);
        require(!hasVoted[id][msg.sender]);

        uint256 power = votingPower(msg.sender);
        require(power > 0);

        hasVoted[id][msg.sender] = true;

        if (support) {
            v.yesVotes += power;
        } else {
            v.noVotes += power;
        }

        if (v.yesVotes >= v.votingPowerThreshold) {
            finalizeVoting(id);
        }
    }

    function finalizeVoting(bytes32 id) public {
        Voting storage v = votings[id];

        require(!v.finalized);
        require(
            block.timestamp >= v.deadline ||
            v.yesVotes >= v.votingPowerThreshold
        );

        v.finalized = true;

        RESULT_NFT.mintResult(
            owner(),
            id,
            v.yesVotes,
            v.noVotes,
            v.yesVotes >= v.noVotes
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
