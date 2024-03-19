// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title CaffeineHeadBlockchainCoffee
 * @author Sandip Ghimire
 * @notice Contract to store and manage coffee product data into the blockchain and users can buy coffee products in different quantities.
 */
contract Caffeineheadblockchaincoffee {
    error NotOwner();
    error NotAllowedAddress();
    error ProductDoesnotExistForId(uint256 id);
    error ProductAlreadyExistsForId(uint256 id);

    event productDataRetrieved(
        uint256 id,
        string name,
        string description,
        uint256 price,
        uint256 availableQuantity,
        uint256 weightInGram,
        string expiryDate
    );
    event productDataStored(
        uint256 id,
        string name,
        string description,
        uint256 price,
        uint256 availableQuantity,
        uint256 weightInGram,
        string expiryDate
    );
    event productDataDeleted(uint256 id);
    event productDataUpdated(
        uint256 id,
        string name,
        string description,
        uint256 price,
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

    constructor(address _owner) {
        owner = _owner;
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
        uint256 price;
        uint256 availableQuantity;
        uint256 weightInGram;
        string expiryDate;
    }

    // struct to store data when product is bought
    struct BoughtProduct {
        uint256 id;
        uint256 quantity;
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
     * @param price The price of the product
     * @param availableQuantity The available quantity of the product
     * @dev can only be called by owner
     */

    function store(
        uint256 productId,
        string memory name,
        string memory description,
        uint256 price,
        uint256 availableQuantity,
        uint256 weightInGram,
        string memory expiryDate
    ) external onlyowner {
        if (bytes(idToProductData[productId].name).length != 0) {
            revert ProductAlreadyExistsForId(productId);
        }
        idToProductData[productId].name = name;
        idToProductData[productId].description = description;
        idToProductData[productId].price = price;
        idToProductData[productId].availableQuantity = availableQuantity;
        idToProductData[productId].weightInGram = weightInGram;
        idToProductData[productId].expiryDate = expiryDate;
        emit productDataStored(productId, name, description, price, availableQuantity, weightInGram, expiryDate);
    }

    /**
     * @notice function to retrieve product data
     * @param id The id of the product whose data you want to retrieve
     * @param name The name of the product
     * @param description The description of the product
     * @param price The price of the product
     * @param availableQuantity The available quantity of the product
     */
    function retrieve(uint256 id)
        public
        returns (
            string memory name,
            string memory description,
            uint256 price,
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
        price = data.price;
        availableQuantity = data.availableQuantity;
        weightInGram = data.weightInGram;
        expiryDate = data.expiryDate;
        emit productDataRetrieved(id, name, description, price, availableQuantity, weightInGram, expiryDate);
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
     * @param price The price of the product to update
     * @param availableQuantity The available quantity of the product to update
     * @dev can only be called by the owner
     */
    function updateData(
        uint256 id,
        string memory name,
        string memory description,
        uint256 price,
        uint256 availableQuantity,
        uint256 weightInGram,
        string memory expiryDate
    ) external onlyowner {
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        idToProductData[id].name = name;
        idToProductData[id].description = description;
        idToProductData[id].price = price;
        idToProductData[id].availableQuantity = availableQuantity;
        idToProductData[id].weightInGram = weightInGram;
        idToProductData[id].expiryDate = expiryDate;
        emit productDataUpdated(id, name, description, price, availableQuantity, weightInGram, expiryDate);
    }

    /**
     * @notice function to buy a single product Item
     * @param id The id of the product to buy
     */
    function buySingleProductItem(uint256 id) external payable {
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        require(msg.value >= idToProductData[id].price, "Not enough balance");
        require(idToProductData[id].availableQuantity > 0, "Out of Stock");
        idToProductData[id].availableQuantity--;
        buyerToBoughtProduct[msg.sender] = BoughtProduct({id: id, quantity: 1});

        // Sending excess value back to the buyer
        if (msg.value > idToProductData[id].price) {
            (bool success,) = msg.sender.call{value: msg.value - idToProductData[id].price}("");
            require(success, "Excess amount transfer failed");
        }
        emit productBought(id, msg.sender, 1);
    }

    /**
     * @notice function to buy a product Item in bulk
     * @param id The id of the product to buy
     * @param quantity The quantity of the product to buy
     */
    function buyProductItemInBulk(uint256 id, uint256 quantity) external payable {
        if (bytes(idToProductData[id].name).length == 0) {
            revert ProductDoesnotExistForId(id);
        }
        require(msg.value >= idToProductData[id].price * quantity, "Not enough balance");
        require(idToProductData[id].availableQuantity >= quantity, "Out of Stock");
        idToProductData[id].availableQuantity -= quantity;
        buyerToBoughtProduct[msg.sender] = BoughtProduct({id: id, quantity: quantity});

        // Sending excess value back to the buyer
        if (msg.value > idToProductData[id].price * quantity) {
            (bool success,) = msg.sender.call{value: msg.value - idToProductData[id].price * quantity}("");
            require(success, "Excess amount transfer failed");
        }
        emit productBought(id, msg.sender, quantity);
    }

    /**
     * @notice function to withdraw funds from the contract
     */
    function withdraw() external onlyowner {
        (bool success,) = payable(owner).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}

    //////////////////////////////  Getters   //////////////////////////////

    /**
     *
     * @param buyer The buyer of the product
     * @dev returns the bought product data
     */
    function getBuyerToBoughtProduct(address buyer) public view returns (BoughtProduct memory) {
        return buyerToBoughtProduct[buyer];
    }
}
