// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console2} from "../lib/forge-std/src/Script.sol";
import {Caffeineheadblockchaincoffee} from "../src/caffeineHeadBlockchainCoffee.sol";

contract DeployScript is Script {
    uint256 deployerKey;

    // config to handle price feed addresses and token addresses
    struct Config {
        address weth;
        address wbtc;
        address usdt;
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
    }

    constructor() {
        if (block.chainid == 11155111) deployerKey = vm.envUint("PRIVATE_KEY");
        else if (block.chainid == 31337) deployerKey = vm.envUint("DEFAULT_ANVIL_KEY");
        else deployerKey = vm.envUint("PRIVATE_KEY");
    }

    function run() public returns (Caffeineheadblockchaincoffee cs) {
        vm.startBroadcast(deployerKey);
        cs = new Caffeineheadblockchaincoffee(
            address(uint160(deployerKey)),
            _getConfig().weth,
            _getConfig().wbtc,
            _getConfig().usdt,
            _getConfig().wethUsdPriceFeed,
            _getConfig().wbtcUsdPriceFeed
        );
        vm.stopBroadcast();
    }

    function _getConfig() internal view returns (Config memory _config) {
        if (block.chainid == 11155111) {
            _config = Config({
                usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
                weth: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
                wbtc: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
                wethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                wbtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
            });
        } else if (block.chainid == 31337) {} else {}
        // only restricted to sepolia for this demo
    }
}
