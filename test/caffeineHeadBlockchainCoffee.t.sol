// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "../lib/forge-std/src/Test.sol";
import {Caffeineheadblockchaincoffee} from "../src/caffeineHeadBlockchainCoffee.sol";
import {DeployScript} from "../script/deployCaffeineHeadBlockchainCoffee.s.sol";

contract CaffeineheadblockchaincoffeeTest is Test {
    Caffeineheadblockchaincoffee public coffeeContract;
    address owner;

    function setUp() public {
        DeployScript ds = new DeployScript();
        coffeeContract = ds.run();
        if (block.chainid == 11155111) owner = address(uint160(vm.envUint("PRIVATE_KEY")));
        else if (block.chainid == 31337) owner = address(uint160(vm.envUint("DEFAULT_ANVIL_KEY")));
        else owner = address(uint160(vm.envUint("PRIVATE_KEY")));
    }

    function test_storeProduct() public {
        uint256 productId = 0;
        string memory name = "Caffeine";
        string memory description = "Caffeine Head Blockchain Coffee";
        uint256 usdPrice = 1e18;
        uint256 nativePrice = 1e18;
        uint256 availableQuantity = 100;
        uint256 weightInGram = 100;
        string memory expiryDate = "2022-12-31";

        vm.startPrank(owner);
        coffeeContract.store(
            productId, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
        vm.stopPrank();

        (
            string memory retrievedName,
            string memory retrievedDescription,
            uint256 retrievedUsdPrice,
            uint256 retrievedNativePrice,
            uint256 retrievedAvailableQuantity,
            uint256 retrievedWeightInGram,
            string memory retrievedExpiryDate
        ) = coffeeContract.retrieve(productId);
        assertEq(retrievedName, name);
        assertEq(retrievedDescription, description);
        assertEq(usdPrice, retrievedUsdPrice);
        assertEq(nativePrice, retrievedNativePrice);
        assertEq(retrievedAvailableQuantity, availableQuantity);
        assertEq(retrievedWeightInGram, weightInGram);
        assertEq(retrievedExpiryDate, expiryDate);
    }

    modifier storeProduct() {
        uint256 productId = 0;
        string memory name = "Caffeine";
        string memory description = "Caffeine Head Blockchain Coffee";
        uint256 usdPrice = 1e18;
        uint256 nativePrice = 1e18;
        uint256 availableQuantity = 100;
        uint256 weightInGram = 100;
        string memory expiryDate = "2022-12-31";

        vm.startPrank(owner);
        coffeeContract.store(
            productId, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
        vm.stopPrank();
        _;
    }

    function test_removeProduct() public storeProduct {
        vm.startPrank(owner);
        coffeeContract.removeProduct(1);
        vm.stopPrank();

        // The call to retrieve reverts as there is no product for product id 1
        vm.expectRevert(abi.encodeWithSelector(Caffeineheadblockchaincoffee.ProductDoesnotExistForId.selector, 1));
        coffeeContract.retrieve(1);
    }

    function test_updateProduct() public storeProduct {
        uint256 productId = 0;
        string memory name = "Caffeine";
        string memory description = "Caffeine Head Blockchain Coffee";
        uint256 usdPrice = 1;
        uint256 nativePrice = 100;
        uint256 availableQuantity = 100;
        uint256 weightInGram = 100;
        string memory expiryDate = "2022-12-31";

        vm.startPrank(owner);
        coffeeContract.updateData(
            productId, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
        vm.stopPrank();

        (
            string memory retrievedName,
            string memory retrievedDescription,
            uint256 retrievedUsdPrice,
            uint256 retrievedNativePrice,
            uint256 retrievedAvailableQuantity,
            uint256 retrievedWeightInGram,
            string memory retrievedExpiryDate
        ) = coffeeContract.retrieve(productId);
        assertEq(retrievedName, name);
        assertEq(retrievedDescription, description);
        assertEq(usdPrice, retrievedUsdPrice);
        assertEq(nativePrice, retrievedNativePrice);
        assertEq(retrievedAvailableQuantity, availableQuantity);
        assertEq(retrievedWeightInGram, weightInGram);
        assertEq(retrievedExpiryDate, expiryDate);
    }

    function test_buysingleProductItemNative() public storeProduct {
        address buyer = address(1);
        vm.deal(buyer, 100e18);

        assertEq(buyer.balance, 100e18);

        vm.startPrank(buyer);
        coffeeContract.buySingleProductItemNative{value: 10e18}(0, 10);
        vm.stopPrank();

        assertEq(buyer.balance, 90e18);
        assertEq(address(coffeeContract).balance, 10e18);
        assertEq(coffeeContract.getBuyerToBoughtProduct(buyer).id, 0);
        assertEq(coffeeContract.getBuyerToBoughtProduct(buyer).quantity, 10);
    }
}
