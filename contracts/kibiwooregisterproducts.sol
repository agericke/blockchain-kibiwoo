pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

/// @title A contract for managing Kibiwoo's products registration.
/// @author Álvaro Gericke

contract KibiwooRegisterProducts is Ownable {
	// TODO: Use Safemath library from openzeppelin
	//using SafeMath for uint256;

	event NewProduct(uint id, string name, uint sku, uint category);
	
	/// The number of digits that the identifier of the product will have.
	/// 	The first 16 digits correspond to the shop identifier.
	///		The last 20 digits correspond to the product identifier.
	uint productIdDigits = 36;
	uint productIdModulus = 10 ** productIdDigits;

	enum Categories { Surf, Cycling, Ski }

	Categories constant defaultCategory = Categories.Surf;

	/// @notice Special structure for defining a product
	/// @param name - The name of the product set by the owner of the product
	/// @param sku - The productId that identifies uniquely each product
	struct Product {
		string name;
		uint sku;
		bool isComplement;
		uint category;
	}

	/// Dynamic array to store all the products
	Product[] public products;

	/// Mapping from product to owner store (Ethereum Address).
	mapping (uint => address)  public productToStore;
	/// Mapping from store (Ethereum Address) to product count.
	mapping (address => uint)  public storeProductCount;

	// address[20] public _owners;
	// struct User {
	// 	address user_address;
	// 	string email;
	// 	string name;
	// }

	// User[] private _owners;

	/// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _name String identifying the  name of the product.
    /// @param _sku The 36 digits identifier of the product to be created.
    /// @param _isComplement Boolean that indicates if this product is a complement from another product.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
	function _registerProduct(string memory _name, uint _sku, bool _isComplement, uint _category) internal returns (uint) {
		//_owners[_id] = msg.sender;
		// TODO: deal with categories variable
		// Require that the uint that represents the category coincides with the number of vategories defined
		require(uint(Categories.Ski) >= _category);
		uint id = products.push(Product(_name, _sku, _isComplement, _category)) - 1;
		productToStore[id] = msg.sender;
		// TODO: Use Safemath libarary form openzeppelin
		storeProductCount[msg.sender] += 1;
		emit NewProduct(id, _name, _sku, _category);
		return id;
	}

	/// @notice Generates Random sku as an identifier for the product.
    /// @param _name String identifying the  name of the product.
    /// @return The last `productIdModulus`of the generated random number
	function _generateRandomSku (string memory _name) internal view returns (uint) {
		uint rand = uint(keccak256(abi.encodePacked(_name)));
		return rand % productIdModulus;
	}

	/// @notice Creates a new product with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string. This function sets isComplement to false.
    /// @param _name String identifying the  name of the product.
    /// @param _category An integer that represents the category of the product.
    /// @return The id that uniquely identifies the registered product.
	function createNewProduct(string memory _name, uint _category) public returns(uint) {
		uint randSku = _generateRandomSku(_name);
		uint id = _registerProduct(_name, randSku, false, _category);
		return id;
	}
	// function _createUser(address _user_address, string _email, string _name) private {
	// 	users.push(User(_user_address, _email, _name))
	// }
}