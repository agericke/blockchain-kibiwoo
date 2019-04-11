pragma solidity ^0.5.0;

import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

/// @title A contract for managing Kibiwoo's products registration.
/// @author Álvaro Gericke

contract KibiwooRegisterProducts is Ownable {

	using SafeMath for uint256;

	event NewProduct(uint id, string name, uint sku, Categories category);

	
	/// The number of digits that the identifier of the product will have.
	/// 	The first 16 digits correspond to the shop identifier.
	///		The last 20 digits correspond to the product identifier.
	uint productIdDigits = 36;
	uint productIdModulus = 10 ** productIdDigits;

	enum Categories { Surf, Cycling, Ski }

	Categories constant defaultCategory = Categories.Surf;

	/// @notice Special structure for defining a product
	/// @param name - The name of the product set by the owner o the product
	/// @param sku - The productId that identifies uniquely each product
	struct Product {
		string name;
		uint sku;
		bool isComplement;
		Categories category;
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
    // @param _id The unique identifier of the product to be created.
    /// @param _name String identifying the  name of the product.
    /// @param _sku The 36 digits identifier of the product to be created.
    /// @param _isComplement Boolean that indicates if this product is a complement from another product
    /// @return The number of NFTs owned by `_owner`, possibly zero
	function _registerProduct(string memory _name, uint _sku, bool _isComplement, Categories _category) internal returns (uint) {
		//_owners[_id] = msg.sender;
		uint id = products.push(Product(_name, _sku, _isComplement, _category)) - 1;
		productToStore[id] = msg.sender;
		storeProductCount[msg.sender].add(1);
		emit NewProduct(id, _name, _sku, _category);
		return id;
	}

	function _generateRandomSku (string memory _name) internal view returns (uint) {
		uint rand = uint(keccak256(abi.encodePacked(_name)));
		return rand % productIdModulus;
	}

	function createNewProduct(string memory _name, Categories _category) public {
		uint randSku = _generateRandomSku(_name);
		_registerProduct(_name, randSku, false, _category);
	}
	// function _createUser(address _user_address, string _email, string _name) private {
	// 	users.push(User(_user_address, _email, _name))
	// }
}