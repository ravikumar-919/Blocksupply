// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Blocksupply - Blockchain Supply Chain Management
 * @dev Smart contract for tracking products through supply chain with transparency and authenticity
 * @author Blocksupply Team
 */
contract Blocksupply {
    
    // Events for tracking supply chain activities
    event ProductRegistered(uint256 indexed productId, address indexed manufacturer, string productName);
    event ProductTransferred(uint256 indexed productId, address indexed from, address indexed to, uint256 timestamp);
    event ProductStatusUpdated(uint256 indexed productId, string status, uint256 timestamp);
    
    // Struct to represent a product in the supply chain
    struct Product {
        uint256 id;
        string name;
        address manufacturer;
        address currentOwner;
        string currentStatus;
        uint256 creationTime;
        bool exists;
    }
    
    // Struct to track transfer history
    struct Transfer {
        address from;
        address to;
        uint256 timestamp;
        string status;
    }
    
    // State variables
    mapping(uint256 => Product) public products;
    mapping(uint256 => Transfer[]) public transferHistory;
    mapping(address => bool) public authorizedEntities;
    
    uint256 private nextProductId;
    address public admin;
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedEntities[msg.sender] || msg.sender == admin, "Not authorized");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(products[_productId].exists, "Product does not exist");
        _;
    }
    
    modifier onlyCurrentOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Not the current owner");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        authorizedEntities[msg.sender] = true;
        nextProductId = 1;
    }
    
    /**
     * @dev Core Function 1: Register a new product in the supply chain
     * @param _name Name of the product
     * @param _manufacturer Address of the manufacturer
     * @return productId The unique identifier for the registered product
     */
    function registerProduct(string memory _name, address _manufacturer) 
        external 
        onlyAuthorized 
        returns (uint256) 
    {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(_manufacturer != address(0), "Invalid manufacturer address");
        
        uint256 productId = nextProductId++;
        
        products[productId] = Product({
            id: productId,
            name: _name,
            manufacturer: _manufacturer,
            currentOwner: _manufacturer,
            currentStatus: "Manufactured",
            creationTime: block.timestamp,
            exists: true
        });
        
        // Record initial transfer (creation)
        transferHistory[productId].push(Transfer({
            from: address(0),
            to: _manufacturer,
            timestamp: block.timestamp,
            status: "Manufactured"
        }));
        
        emit ProductRegistered(productId, _manufacturer, _name);
        emit ProductStatusUpdated(productId, "Manufactured", block.timestamp);
        
        return productId;
    }
    
    /**
     * @dev Core Function 2: Transfer product ownership in the supply chain
     * @param _productId ID of the product to transfer
     * @param _newOwner Address of the new owner
     * @param _status New status of the product (e.g., "In Transit", "Delivered", "Sold")
     */
    function transferProduct(uint256 _productId, address _newOwner, string memory _status) 
        external 
        productExists(_productId)
        onlyCurrentOwner(_productId)
    {
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != products[_productId].currentOwner, "Cannot transfer to current owner");
        require(bytes(_status).length > 0, "Status cannot be empty");
        
        address previousOwner = products[_productId].currentOwner;
        
        // Update product ownership and status
        products[_productId].currentOwner = _newOwner;
        products[_productId].currentStatus = _status;
        
        // Record transfer in history
        transferHistory[_productId].push(Transfer({
            from: previousOwner,
            to: _newOwner,
            timestamp: block.timestamp,
            status: _status
        }));
        
        emit ProductTransferred(_productId, previousOwner, _newOwner, block.timestamp);
        emit ProductStatusUpdated(_productId, _status, block.timestamp);
    }
    
    /**
     * @dev Core Function 3: Get complete product information and transfer history
     * @param _productId ID of the product to query
     * @return product Product details
     * @return transfers Array of all transfers for the product
     */
    function getProductDetails(uint256 _productId) 
        external 
        view 
        productExists(_productId)
        returns (Product memory product, Transfer[] memory transfers) 
    {
        return (products[_productId], transferHistory[_productId]);
    }
    
    // Additional utility functions
    
    /**
     * @dev Add or remove authorized entities (manufacturers, distributors, retailers)
     * @param _entity Address to authorize/deauthorize
     * @param _authorized Boolean indicating authorization status
     */
    function setAuthorizedEntity(address _entity, bool _authorized) external onlyAdmin {
        require(_entity != address(0), "Invalid entity address");
        authorizedEntities[_entity] = _authorized;
    }
    
    /**
     * @dev Update product status without transferring ownership
     * @param _productId ID of the product
     * @param _status New status
     */
    function updateProductStatus(uint256 _productId, string memory _status) 
        external 
        productExists(_productId)
        onlyCurrentOwner(_productId)
    {
        require(bytes(_status).length > 0, "Status cannot be empty");
        
        products[_productId].currentStatus = _status;
        emit ProductStatusUpdated(_productId, _status, block.timestamp);
    }
    
    /**
     * @dev Get the current number of registered products
     * @return count Total number of products registered
     */
    function getTotalProducts() external view returns (uint256) {
        return nextProductId - 1;
    }
    
    /**
     * @dev Verify if a product is authentic by checking if it exists in the blockchain
     * @param _productId ID of the product to verify
     * @return isAuthentic Boolean indicating if the product is registered and authentic
     */
    function verifyAuthenticity(uint256 _productId) external view returns (bool) {
        return products[_productId].exists;
    }
}
