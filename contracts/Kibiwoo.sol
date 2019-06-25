pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/drafts/Counters.sol';

/// @author Álvaro Gericke
/// @title A contract for managing Kibiwoo's products registration.
contract Kibiwoo is Ownable {
    // TODO: Use Safemath library from openzeppelin
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /// @notice Product object definition.
    /// @param sku - The productId that identifies uniquely each product.
    /// @param category - Product category.
    /// @param min_rent_time - Integer to set the minimum rental time for the product.
    /// @param name - The name of the product set by the owner of the product.
    struct Product {
        uint sku;
        uint category;
        uint min_rent_time;
        string name;
    }

    /// @notice Complement object definition
    /// @param productId - Identifier of the product to which this complement belongs.
    /// @param subcategory - Subcategory of the complement.
    /// @param name - Name of the complement.
    struct Complement {
        uint productId;
        uint subcategory;
        string name;
    }

    /// Enum type for defining products categories.
    enum Categories {Surf, Cycling, Ski}

    /// Enum type for defining complements subcategories
    enum Subcategories {Wetsuit, Helmet, Boots}

    address payable public kibiwooAdmin;

    /// The number of digits that the identifier of the product will have.
    ///     The first 16 digits correspond to the shop identifier.
    ///     The last 20 digits correspond to the product identifier.
    uint constant productIdDigits = 36;
    uint productIdModulus = 10 ** productIdDigits;

    Categories constant defaultCategory = Categories.Surf;

    /// Dynamic arrays to persist stores, products and complements.
    Product[] public products;
    Complement[] public complements;

    /// Mapping from product to owner store (Ethereum Address).
    mapping (uint => address)  public productToStore;
    /// Mapping from store (Ethereum Address) to product count.
    mapping (address =>  Counters.Counter)  public storeProductCount;

    event NewProduct(uint id, uint sku, uint category, string name);

    // TODO: Need to check if I need to call constructor of Ownable.sol
    constructor() public {
        kibiwooAdmin = msg.sender;
    }

    function() external payable {

    }

    /// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string. This function sets 
    ///  isComplement to false.
    /// @param _name String identifying the  name of the product.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
    function createNewProduct(string memory _name, uint _category) public returns(uint) {
        uint randSku = _generateRandomSku(_name);
        uint id = _registerProduct(_name, randSku, _category);
        return id;
    }

    /// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _name String identifying the  name of the product.
    /// @param _sku The 36 digits identifier of the product to be created.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
    // TODO: connect with _mint function and emit new Transfer product form address 0
    //      to indicate the cration of a product.
    function _registerProduct(string memory _name, uint _sku, uint _category) 
        internal 
        returns (uint) 
    {
        // TODO: deal with categories variable
        // Require that the uint that represents the category coincides with the number of 
        //  categories defined.
        require(uint(Categories.Ski) >= _category);
        uint min_rent_time = 1 hours;
        uint id = products.push(Product(_sku, _category, min_rent_time, _name)) - 1;
        productToStore[id] = msg.sender;
        storeProductCount[msg.sender].increment();
        emit NewProduct(id, _sku, _category, _name);
        return id;
    }

    /// @notice Generates Random sku as an identifier for the product.
    /// @param _name String identifying the  name of the product.
    /// @return The last `productIdModulus`of the generated random number
    function _generateRandomSku (string memory _name) internal view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(_name)));
        return rand % productIdModulus;
    }
}