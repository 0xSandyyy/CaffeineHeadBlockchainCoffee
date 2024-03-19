// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {Caffeineheadblockchaincoffee} from "../src/caffeineHeadBlockchainCoffee.sol";

contract DeployScript is Script {
    uint256 deployerKey;

    constructor() {
        if (block.chainid == 11155111) deployerKey = vm.envUint("SEPOLIA_KEY");
        else if (block.chainid == 31337) deployerKey = vm.envUint("DEFAULT_ANVIL_KEY");
        else deployerKey = vm.envUint("PRIVATE_KEY");
    }

    function run() public returns (Caffeineheadblockchaincoffee cs) {
        vm.startBroadcast(deployerKey);
        cs = new Caffeineheadblockchaincoffee(address(uint160(deployerKey)));
        vm.stopBroadcast();
    }
}
