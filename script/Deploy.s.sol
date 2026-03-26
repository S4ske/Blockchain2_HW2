pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {VegaVotingToken} from "../src/VegaVotingToken.sol";
import {VotingResultNFT} from "../src/VotingResultNFT.sol";
import {VegaVoting} from "../src/VegaVoting.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        VegaVotingToken token = new VegaVotingToken();
        VotingResultNFT nft = new VotingResultNFT();
        VegaVoting voting = new VegaVoting(address(token), address(nft));

        nft.transferOwnership(address(voting));

        vm.stopBroadcast();
    }
}
