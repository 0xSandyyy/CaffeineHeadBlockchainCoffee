// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";

/**
 * @title CaffeineHeadBlockchainCoffee
 * @author Sandip Ghimire
 * @notice Contract to store and manage coffee product data into the blockchain and users can buy coffee products in different quantities.
 */
contract Caffeineheadblockchaincoffee {
    using SafeERC20 for IERC20;
    using OracleLib for AggregatorV3Interface;

    /////////////////////////////////// ERRORS //////////////////////////////////
    error NotOwner();
    error NotAllowedAddress();
    error ProductDoesnotExistForId(uint256 id);
    error ProductAlreadyExistsForId(uint256 id);

    //////////////////////////////// EVENTS //////////////////////////////////////
    event productDataRetrieved(
        uint256 id,
        string name,
        string description,
        uint256 usdPrice,
        uint256 nativePrice,
        uint256 availableQuantity,
        uint256 weightInGram,
        string expiryDate
    );
    event productDataStored(
        uint256 id,
        string name,
        string description,
        uint256 usdPrice,
        uint256 nativePrice,
        uint256 availableQuantity,
        uint256 weightInGram,
        string expiryDate
    );
    event productDataDeleted(uint256 id);
    event productDataUpdated(
        uint256 id,
        string name,
        string description,
        uint256 usdPrice,
        uint256 nativePrice,
        uint256 availableQuantity,
        uint256 weightInGram,
        string expiryDate
    );
    event productBought(uint256 id, address buyer, uint256 quantity);

    // mapping from product id to product data
    mapping(uint256 id => ProductData) idToProductData;

    // mapping from buyer address to data of bought product
    mapping(address buyer => BoughtProduct) buyerToBoughtProduct;

    // address of the owner who has privileges to special operations
    address private owner;

    // tokenConfiguration initialized
    TokenConfig tokenConfig;

    // Precision to scale price returned by /usd price feed i.e 8
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;

    enum WITHDRAW_TOKEN_TYPE {
        NATIVE,
        WETH,
        WBTC,
        USDT
    }

    /**
     *
     * @notice constructor
     * @param _owner The address of the owner to transfer ownership to
     * @param _weth The address of the WETH token
     * @param _wbtc The address of the WBTC token
     * @param _usdt The address of the USDT token
     * @param _wethUsdPriceFeed The address of the WETH/USD price feed
     * @param _wbtcUsdPriceFeed The address of the WBTC/USD price feed
     */
    constructor(
        address _owner,
        address _weth,
        address _wbtc,
        address _usdt,
        address _wethUsdPriceFeed,
        address _wbtcUsdPriceFeed
    ) {
        owner = _owner;
        tokenConfig = TokenConfig({
            weth: _weth,
            wbtc: _wbtc,
            usdt: _usdt,
            wethUsdPriceFeed: _wethUsdPriceFeed,
            wbtcUsdPriceFeed: _wbtcUsdPriceFeed
        });
    }

    // modifier to restrict operations only to the owner
    modifier onlyowner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // struct to store input/output data
    struct ProductData {
        uint256 id;
        string name;
        string description;
        uint256 usdPrice;
        uint256 nativePrice;
        uint256 availableQuantity;
        uint256 weightInGram;
        string expiryDate;
    }

    // struct to store data when product is bought
    struct BoughtProduct {
        uint256 id;
        uint256 quantity;
    }

    // struct to store tokens and price feeds configuration data
    struct TokenConfig {
        address weth;
        address wbtc;
        address usdt;
        address wethUsdPriceFeed;
        address wbtcUsdPriceFeed;
    }

    /**
     * @notice function to transfer ownership from one owner to other
     * @param newOwner The address of the new owner to transfer ownership.
     * @dev can only be called by owner
     */
    function transferOwnership(address newOwner) external onlyowner {
        if (newOwner == address(0)) {
            revert NotAllowedAddress();
        }
        owner = newOwner;
    }

    /**
     * @notice function to store data
     * @param productId The id of the product
     * @param name The name of the product
     * @param description The description of the product
     * @param usdPrice The price of the product in usd
     * @param nativePrice The price of the product in native token
     * @param availableQuantity The available quantity of the product
     * @dev can only be called by owner
     */
    function store(
        uint256 productId,
        string memory name,
        string memory description,
        uint256 usdPrice,
        uint256 nativePrice,
        uint256 availableQuantity,
        uint256 weightInGram,
        string memory expiryDate
    ) external onlyowner {
        if (bytes(idToProductData[productId].name).length != 0) {
            revert ProductAlreadyExistsForId(productId);
        }
        idToProductData[productId].name = name;
        idToProductData[productId].description = description;
        idToProductData[productId].usdPrice = usdPrice;
        idToProductData[productId].nativePrice = nativePrice;
        idToProductData[productId].availableQuantity = availableQuantity;
        idToProductData[productId].weightInGram = weightInGram;
        idToProductData[productId].expiryDate = expiryDate;
        emit productDataStored(
            productId, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
    }

    /**
     * @notice function to retrieve product data
     * @param id The id of the product whose data you want to retrieve
     * @param name The name of the product
     * @param description The description of the product
     * @param nativePrice The native price of the product
     * @param usdPrice The price of the product in usd
     * @param availableQuantity The available quantity of the product
     */
    function retrieve(uint256 id)
        public
        returns (
            string memory name,
            string memory description,
            uint256 usdPrice,
            uint256 nativePrice,
            uint256 availableQuantity,
            uint256 weightInGram,
            string memory expiryDate
        )
    {
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        ProductData memory data = idToProductData[id];
        name = data.name;
        description = data.description;
        usdPrice = data.usdPrice;
        nativePrice = data.nativePrice;
        availableQuantity = data.availableQuantity;
        weightInGram = data.weightInGram;
        expiryDate = data.expiryDate;
        emit productDataRetrieved(
            id, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
    }

    /**
     * @notice function to delete product data
     * @param id The id of the product to remove
     * @dev can only be called by the owner
     */
    function removeProduct(uint256 id) external onlyowner {
        delete idToProductData[id];
        emit productDataDeleted(id);
    }

    /**
     * @notice function to update product data
     * @param id The id of the product
     * @param name The name of the product to update
     * @param description The description of the product to update
     * @param usdPrice The price of the product to update in usd
     * @param nativePrice The price of the product to update in native token
     * @param availableQuantity The available quantity of the product to update
     * @dev can only be called by the owner
     */
    function updateData(
        uint256 id,
        string memory name,
        string memory description,
        uint256 usdPrice,
        uint256 nativePrice,
        uint256 availableQuantity,
        uint256 weightInGram,
        string memory expiryDate
    ) external onlyowner {
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        idToProductData[id].name = name;
        idToProductData[id].description = description;
        idToProductData[id].usdPrice = usdPrice;
        idToProductData[id].nativePrice = nativePrice;
        idToProductData[id].availableQuantity = availableQuantity;
        idToProductData[id].weightInGram = weightInGram;
        idToProductData[id].expiryDate = expiryDate;
        emit productDataUpdated(
            id, name, description, usdPrice, nativePrice, availableQuantity, weightInGram, expiryDate
        );
    }

    /**
     * @notice function to buy a product Item with native currency e.g ETH for Ethereum, Matic for Polygon,...
     * @param id The id of the product to buy
     * @param quantity The quantity of the product to buy. If 0, it will be set to 1
     */
    function buySingleProductItemNative(uint256 id, uint256 quantity) external payable {
        // Checks
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        if (quantity == 0) {
            quantity == 1;
        }
        require(msg.value >= getPrice(id, true) * quantity, "Not enough balance");
        require(idToProductData[id].availableQuantity >= quantity, "Out of Stock");

        // Effects
        idToProductData[id].availableQuantity -= quantity;
        buyerToBoughtProduct[msg.sender] =
            BoughtProduct({id: id, quantity: buyerToBoughtProduct[msg.sender].quantity + quantity});

        // Interactions
        // Sending excess value back to the buyer
        if (msg.value > getPrice(id, true) * quantity) {
            (bool success,) = msg.sender.call{value: msg.value - getPrice(id, true) * quantity}("");
            require(success, "Excess amount transfer failed");
        }
        emit productBought(id, msg.sender, quantity);
    }

    /**
     * @notice function to withdraw funds from the contract
     * @param value The token type to withdraw
     * @param amount The amount to withdraw
     */
    function withdraw(WITHDRAW_TOKEN_TYPE value, uint256 amount) external onlyowner {
        if (value == WITHDRAW_TOKEN_TYPE.NATIVE) {
            (bool success,) = payable(owner).call{value: address(this).balance}("");
            require(success, "Withdrawal failed");
        } else if (value == WITHDRAW_TOKEN_TYPE.WETH) {
            IWETH(tokenConfig.weth).transfer(owner, amount);
        } else if (value == WITHDRAW_TOKEN_TYPE.WBTC) {
            IERC20(tokenConfig.wbtc).safeTransfer(owner, IERC20(tokenConfig.wbtc).balanceOf(address(this)));
        } else if (value == WITHDRAW_TOKEN_TYPE.USDT) {
            IERC20(tokenConfig.usdt).safeTransfer(owner, IERC20(tokenConfig.usdt).balanceOf(address(this)));
        } else {
            revert("Invalid token type");
        }
    }

    receive() external payable {}

    /**
     *
     * @notice function to buy a product with USDT
     * @param id The id of the product
     * @param quantity The quantity of the product to buy. If 0, it will be set to 1
     * @dev Though price feed can be used to get accurate amount which is fluctuating between $0.98 - $1.01 per token, but the price is assumed to be 1$/1 token for easier implementation.
     */
    function buySingleProductItemUSDT(uint256 id, uint256 quantity) public {
        // Checks
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        if (quantity == 0) {
            quantity == 1;
        }
        uint256 price = getPrice(id, false) * quantity;
        if (IERC20(tokenConfig.usdt).allowance(msg.sender, address(this)) <= price) {
            revert("Not enough allowance!");
        }
        require(idToProductData[id].availableQuantity >= quantity, "Out of Stock");

        // Effects
        idToProductData[id].availableQuantity -= quantity;
        buyerToBoughtProduct[msg.sender] =
            BoughtProduct({id: id, quantity: buyerToBoughtProduct[msg.sender].quantity + quantity});

        // Interactions
        IERC20(tokenConfig.usdt).safeTransferFrom(msg.sender, address(this), price);
        emit productBought(id, msg.sender, quantity);
    }

    /**
     * @notice function to buy a product with WBTC
     * @param id The id of the product to buy
     * @param quantity The quantity of the product to buy. If 0, it will be set to 1
     */
    function buySingleProductItemWBTC(uint256 id, uint256 quantity) public {
        // Checks
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        if (quantity == 0) {
            quantity == 1;
        }
        uint256 price = getTokenAmountFromUsd(tokenConfig.wbtcUsdPriceFeed, getPrice(id, false)) * quantity;
        if (IERC20(tokenConfig.wbtc).allowance(msg.sender, address(this)) <= price) {
            revert("Not enough allowance!");
        }
        require(idToProductData[id].availableQuantity >= quantity, "Out of Stock");

        // Effects
        idToProductData[id].availableQuantity -= quantity;
        buyerToBoughtProduct[msg.sender] =
            BoughtProduct({id: id, quantity: buyerToBoughtProduct[msg.sender].quantity + quantity});

        // Interactions
        IERC20(tokenConfig.wbtc).safeTransferFrom(msg.sender, address(this), price);
        emit productBought(id, msg.sender, quantity);
    }

    /**
     * @notice function to buy a product with WETH
     * @param id The id of the product to buy
     * @param quantity The quantity of the product to buy. If 0, it will be set to 1
     */
    function buySingleProductItemWETH(uint256 id, uint256 quantity) public {
        // Checks
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        if (quantity == 0) {
            quantity == 1;
        }
        uint256 price = getTokenAmountFromUsd(tokenConfig.wethUsdPriceFeed, getPrice(id, false)) * quantity;
        if (IERC20(tokenConfig.weth).allowance(msg.sender, address(this)) <= price) {
            revert("Not enough allowance!");
        }
        require(idToProductData[id].availableQuantity >= quantity, "Out of Stock");

        // Effects
        idToProductData[id].availableQuantity -= quantity;
        buyerToBoughtProduct[msg.sender] =
            BoughtProduct({id: id, quantity: buyerToBoughtProduct[msg.sender].quantity + quantity});

        // Interactions
        IERC20(tokenConfig.weth).safeTransferFrom(msg.sender, address(this), price);
        emit productBought(id, msg.sender, quantity);
    }

    //////////////////////////////  Getters   //////////////////////////////

    /**
     *
     * @param buyer The buyer of the product
     * @dev returns the bought product data
     */
    function getBuyerToBoughtProduct(address buyer) public view returns (BoughtProduct memory) {
        return buyerToBoughtProduct[buyer];
    }

    /**
     *
     * @param id The id of the product
     * @param native bool to determine whether to get native price or usd price
     * @dev returns the price of the product
     */
    function getPrice(uint256 id, bool native) public view returns (uint256) {
        return native ? idToProductData[id].nativePrice : idToProductData[id].usdPrice;
    }

    /**
     *
     * @param priceFeed The price feed address
     * @param usdAmountInWei The amount in usd
     * @dev returns the amount in token amount as per the price feed
     */
    function getTokenAmountFromUsd(address priceFeed, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface interfacev3 = AggregatorV3Interface(priceFeed);
        (, int256 price,,,) = interfacev3.staleCheckLatestRoundData();
        address token = priceFeed == tokenConfig.wethUsdPriceFeed ? tokenConfig.weth : tokenConfig.wbtc;
        uint256 decimalsPrecision = token == tokenConfig.weth ? 10 ** 18 : 10 ** 8;
        return (usdAmountInWei * decimalsPrecision) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }
    // 10e18 * 1e18 / (2000e8 * 1e10) = 0.005 ETH = 10$
    // $100e18 * 1e8  / 66000e8 * 1e10 = 151515.151515152 ~ 0.001515152 BTC = 100$
}
