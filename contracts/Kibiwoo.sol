pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/drafts/Counters.sol';
import 'openzeppelin-solidity/contracts/token/ERC721/ERC721.sol';

// TODO: Check gas consumption of every function and see if it is posible to optimize.
// TODO: Change solution to a ERC721 Metadata one.

/// @author Álvaro Gericke
/// @title A contract for managing Kibiwoo's products registration.
contract Kibiwoo is Ownable, ERC721 {

    // TODO: Use Safemath library from openzeppelin
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    /// @notice Product object definition.
    /// @param sku - The productId that identifies uniquely each product.
    /// @param category - Product category.
    /// @param min_rent_time - Integer to set the minimum rental time for the product.
    /// @param name - The name of the product set by the owner of the product.
    struct Product {
        uint256 sku;
        uint256 category;
        uint256 min_rent_time;
        string name;
    }

    /// @notice Complement object definition
    /// @param productId - Identifier of the product to which this complement belongs.
    /// @param subcategory - Subcategory of the complement.
    /// @param name - Name of the complement.
    struct Complement {
        uint256 productId;
        uint256 subcategory;
        string name;
    }

    /// Enum type for defining products categories.
    enum Categories {Surf, Cycling, Ski}

    /// Enum type for defining complements subcategories
    enum Subcategories {Wetsuit, Helmet, Boots}

    address payable private kibiwooAdmin;

    /// The number of digits that the identifier of the product will have.
    ///     The first 16 digits correspond to the shop identifier.
    ///     The last 20 digits correspond to the product identifier.
    uint256 constant productIdDigits = 36;
    uint256 productIdModulus = 10 ** productIdDigits;

    /// Dynamic arrays to persist stores, products and complements.
    Product[] public products;
    Complement[] public complements;

    /// Mapping from complement to product.
    mapping (uint256 => uint256)  private _complementToToken;
    /// Mapping from productID to complements count.
    mapping (uint256 => Counters.Counter) private _tokenComplementCount;
    /// Mapping from productId to bool indicating if product is booked.
    mapping (uint256 => bool) private _productBooked;

    event NewProduct(uint256 id, uint256 sku, uint256 category, string name);
    event NewComplement(uint256 tokenId, uint256 complementId, uint256 subcategory, string name);
    event Book(address indexed booker, uint256 tokenId);

    constructor() public {
        kibiwooAdmin = msg.sender;
    }

    function() external payable {

    }

    /// @notice Withdraws all the balance in the contract back to owner of the contract
    function withdraw() external onlyOwner {
        address payable _owner = address(uint160(owner()));
        _owner.transfer(address(this).balance);
    }

    /// @notice Returns all the products with its complements that are owned by a specific shop.
    /// @param _owner Address of the shop to retrieve the products from it.
    /// @return An array with all the IDs of the products and their complements owned by that shop
    function getProductsByShop (address _owner) external view returns (uint[] memory) {

        require(balanceOf(_owner) != 0, "ERC721: Querying products for a store with 0 products.");
        
        uint[] memory productsResult = new uint[](balanceOf(_owner));
        // Iterate over all the products and build an array of products
        uint256 counter = 0;
        for (uint i = 0; i < products.length; i++) {
            if (ownerOf(i) == _owner) {
                productsResult[counter] = i;
                // TODO: Implement usage of SafeMath for the Counter
                counter++;
            }
        }
        return productsResult;
    }

    /// @notice Require that the owner of the product is the caller of the function.
    modifier onlyOwnerOf (uint _productId) {
        require (ownerOf(_productId) == msg.sender, "ERC721: Action restricted to owner of product.");
        _;
    }                                                                   

    /// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string. This function sets 
    ///  isComplement to false.
    /// @param _name String identifying the  name of the product.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
    function createNewProduct(string memory _name, uint256 _category) public returns(uint256) {
        uint256 randSku = _generateRandomSku(_name);
        uint256 id = _registerProduct(_name, randSku, _category);
        
        return id;
    }

    /// @notice Adds a new complement to the actual product.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _productId The unique identifier of the product to which a complement will be added.
    /// @param _name String identifying the  name of the complement.
    function addComplement(uint256 _productId, uint256 _subcategory, string memory _name) 
        public 
        onlyOwnerOf(_productId) 
        returns (uint256) 
    {

        uint256 complementId = _registerComplement(_productId, _subcategory, _name);
        return complementId;
    }

    /// @notice Mark a product as booked.
    /// @dev Only use for first version of front-end.
    /// @param tokenId Id of the product which we wiil mark as booked.
    /// @return bool Actual state of booking. (True indicates booked).
    function book(uint256 tokenId) public returns(bool) {
        // TODO: We check this condition already with isBooked, so not necessary.
        //require(_exists(tokenId), "ERC721: book query for nonexistent token");

        _book(tokenId);

        return true;
    }

    /// @notice Gets the actual kibiwoo Administrator.
    /// @return address representing Kibiwoo's Administrator address.
    function getAdmin() public view returns(address) {
        return kibiwooAdmin;
    }

    /// @notice Gets the total amount of products created.
    /// @return uint256 representing the amount of products created.
    function getProductsCount() public view returns(uint256) {
        return products.length;
    }

    /// @notice Gets the productId for a specific complement Id.
    /// @return uint256 productId of a complement's product.
    function getProductOfComplement(uint256 complementId) public view returns(uint256) {
        // TODO: find a nother way to assure the existance of a complement.
        require(complements.length > complementId, "Querying non-existent complement.");

        return _complementToToken[complementId];
    }

    /// @notice Gets the number of complements a product has.
    /// @return uint256 number of complements of a product.
    function getComplementsCount(uint256 tokenId) public view returns(uint256) {
        // TODO: find a nother way to assure the existance of a complement.
        require(_exists(tokenId), "ERC721: complements count query for nonexistent token.");

        return _tokenComplementCount[tokenId].current();
    }

    /// @notice Check if a product is booked.
    /// @param tokenId The product Id to check if it is booked.
    /// @return bool indicating if it is booked.
    function isBooked(uint256 tokenId) public view returns(bool) {

        require(_exists(tokenId), "ERC721: isBooked query for nonexistent token");
        
        return _productBooked[tokenId];
    }

    /// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _name String identifying the  name of the product.
    /// @param _sku The 36 digits identifier of the product to be created.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
    function _registerProduct(string memory _name, uint256 _sku, uint256 _category) 
        internal
        returns (uint256) 
    {
        require(uint256(Categories.Ski) >= _category, "Invalid category.");
        uint256 min_rent_time = 1 hours;
        uint256 id = products.push(Product(_sku, _category, min_rent_time, _name)) - 1;

        _mint(msg.sender, id);

        // Create new entry with book equal to false.
        // TODO: False is default value so maybe this is nt necessary.
        _productBooked[id] = false;

        emit NewProduct(id, _sku, _category, _name);

        return id;
    }

    /// @notice Creates a new complement with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _productId Id of the product which the complement is added to.
    /// @param _subcategory An integer that represents the category of the product.
    /// @param _name String identifying the  name of the product.
    /// @return The id that uniquely identifies the registered product.
    function _registerComplement(uint256 _productId, uint256 _subcategory, string memory _name) 
        internal 
        returns (uint256) 
    {
        // TODO: deal with categories variable.
        require(uint256(Subcategories.Boots) >= _subcategory, "Invalid subcategory.");
        
        uint256 complementId = complements.push(Complement(_productId, _subcategory, _name)) - 1;
        _complementToToken[complementId] = _productId;
        _tokenComplementCount[_productId].increment();
        
        emit NewComplement(_productId, complementId, _subcategory, _name);
        
        return complementId;
    }

    /// @notice Internal function for handling the booking of a product.
    /// @dev Only use for first version of front-end.
    /// @param _productId Id of the product which we wiil mark as booked.
    /// @return bool Actual state of booking. (True indicates booked).
    function _book(uint256 _productId) internal {

        require(!isBooked(_productId), "Cannot Booked an already booked product.");
        
        _productBooked[_productId] = true;

        emit Book(msg.sender, _productId);
    }

    /// @notice Generates Random sku as an identifier for the product.
    /// @param _name String identifying the  name of the product.
    /// @return The last `productIdModulus`of the generated random number
    function _generateRandomSku (string memory _name) internal view returns (uint256) {
        uint256 rand = uint(keccak256(abi.encodePacked(_name)));
        return rand % productIdModulus;
    }
}