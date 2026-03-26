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

    function testVotingPowerUsesMultiplier() public view {
        uint256 remain = 30 days;
        uint256 expectedUser1 = 100 ether * 2 * remain * remain;
        uint256 expectedUser2 = 100 ether * 3 * remain * remain;

        assertEq(voting.votingPower(user1), expectedUser1);
        assertEq(voting.votingPower(user2), expectedUser2);
    }

    function testOnlyOwnerCanCreateVoting() public {
        vm.prank(user1);
        vm.expectRevert();
        voting.createVoting(keccak256("vote-owner"), block.timestamp + 1 days, 1, "Approve proposal");
    }

    function testVotingFinalizesAndMintsResult() public {
        bytes32 id = keccak256("vote-finalize");

        voting.createVoting(id, block.timestamp + 1 days, 1, "Approve proposal");

        vm.prank(user1);
        voting.vote(id, true);

        (,,,, uint256 yesVotes, uint256 noVotes, bool finalized) = voting.votings(id);
        assertTrue(finalized);
        assertEq(yesVotes, voting.votingPower(user1));
        assertEq(noVotes, 0);
        assertEq(nft.ownerOf(1), address(this));

        (bytes32 resultId, uint256 resultYesVotes, uint256 resultNoVotes, bool passed) = nft.results(1);
        assertEq(resultId, id);
        assertEq(resultYesVotes, yesVotes);
        assertEq(resultNoVotes, noVotes);
        assertTrue(passed);
    }

    function testCannotVoteTwice() public {
        bytes32 id = keccak256("vote-double");

        voting.createVoting(id, block.timestamp + 1 days, type(uint256).max, "Approve proposal");

        vm.prank(user1);
        voting.vote(id, true);

        vm.prank(user1);
        vm.expectRevert();
        voting.vote(id, true);
    }

    function testCanUnstakeAfterExpiry() public {
        uint256 balanceBefore = token.balanceOf(user1);

        vm.warp(block.timestamp + 30 days);

        vm.prank(user1);
        voting.unstake(0);

        assertEq(token.balanceOf(user1), balanceBefore + 100 ether);
    }
}
