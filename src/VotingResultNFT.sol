pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VotingResultNFT is ERC721, Ownable {
    uint256 public tokenId;

    struct Result {
        bytes32 voteId;
        uint256 yesVotes;
        uint256 noVotes;
        bool passed;
    }

    mapping(uint256 => Result) public results;

    constructor() ERC721("VotingResult", "VRES") Ownable(msg.sender) {}

    function mintResult(address to, bytes32 voteId, uint256 yesVotes, uint256 noVotes, bool passed) external onlyOwner {
        tokenId++;

        _mint(to, tokenId);

        results[tokenId] = Result({voteId: voteId, yesVotes: yesVotes, noVotes: noVotes, passed: passed});
    }
}
