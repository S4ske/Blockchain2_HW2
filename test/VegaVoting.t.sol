pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VegaVotingToken} from "../src/VegaVotingToken.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract VegaVotingTest is Test {
    VegaVotingToken token;
    VotingResultNFT nft;
    VegaVoting voting;

    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new VegaVotingToken();
        nft = new VotingResultNFT();
        voting = new VegaVoting(address(token), address(nft));

        nft.transferOwnership(address(voting));

        token.mint(user1, 1000 ether);
        token.mint(user2, 1000 ether);

        vm.startPrank(user1);
        token.approve(address(voting), type(uint256).max);
        voting.stake(100 ether, 30 days, 2);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(voting), type(uint256).max);
        voting.stake(100 ether, 30 days, 3);
        vm.stopPrank();
    }

    function testVoting() public {
    bytes32 id = keccak256("vote1");

    voting.createVoting(
        id,
        block.timestamp + 1 days,
        1,
        "Approve proposal"
    );

    vm.prank(user1);
    voting.vote(id, true);
}
}