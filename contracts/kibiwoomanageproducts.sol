pragma solidity ^0.5.0;

import "./kibiwooregisterproducts.sol";

/// @title A contract that extents Kibiwoo's contract registration functionality for managing product's complements
/// @author Álvaro Gericke
contract KibiwooManageProducts is KibiwooRegisterProducts {

	// Require that the owner of the product is the caller of the function.
	modifier onlyOwnerOf (uint _productId) {
		require (msg.sender == productToStore[_productId]);
		_;
	}

	event NewComplement(uint complementId, uint productId, string name, uint sku);

	/// Dynamic array to store all the products's complements
	// Products[] public complements;

	/// Mapping from complement to product.
	mapping (uint => uint)  public complementToProduct;
	/// Mapping from product to complements count.
	mapping (uint => uint)  public productComplementCount;

	/// @notice Adds a new complement to the actual product.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _productId The unique identifier of the product to which a complement will be added.
    /// @param _name String identifying the  name of the complement.
	function addComplement(uint _productId, string memory _name) public onlyOwnerOf(_productId) returns (uint) {
		uint randSku = _generateRandomSku(_name);
		uint complementId = _registerProduct(_name, randSku, true, products[_productId].category);
		complementToProduct[complementId] = _productId;
		// TODO: Use SafeMath
		productComplementCount[_productId] += 1;
		emit NewComplement(complementId, _productId, _name, randSku);
		return complementId;
	}
}