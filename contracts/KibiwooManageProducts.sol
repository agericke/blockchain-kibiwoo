pragma solidity ^0.5.0;

import "./KibiwooRegisterProducts.sol";

/// @title A contract that extents Kibiwoo's contract registration functionality for managing product's complements
/// @author Álvaro Gericke
contract KibiwooManageProducts is KibiwooRegisterProducts {

	/// Mapping from complement to product.
	mapping (uint => uint)  public complementToProduct;
	/// Mapping from product to complements count.
	mapping (uint => Counters.Counter)  public productComplementCount;

	event NewComplement(uint productId, uint complementId, uint subcategory, string name);

	// Require that the owner of the product is the caller of the function.
	modifier onlyOwnerOf (uint _productId) {
		require (msg.sender == productToStore[_productId]);
		_;
	}

	/// @notice Adds a new complement to the actual product.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _productId The unique identifier of the product to which a complement will be added.
    /// @param _name String identifying the  name of the complement.
	function addComplement(uint _productId, uint _subcategory, string memory _name) public onlyOwnerOf(_productId) returns (uint) {
		uint complementId = _registerComplement(_productId, _subcategory, _name);
		return complementId;
	}

	/// @notice Creates a new complement with id the consecutive one and name specified by caller.
    /// @dev If no name is assigned, it will be assigned an empty string.
    /// @param _productId Id of the product which the complement is added to.
    /// @param _subcategory An integer that represents the category of the product.
    /// @param _name String identifying the  name of the product.
    /// @return The id that uniquely identifies the registered product.
	function _registerComplement(uint _productId, uint _subcategory, string memory _name) internal returns (uint) {
		// TODO: deal with categories variable
		// TODO: Require that the uint that represents the category coincides with the number of categories defined
		// TODO: Require that address is not equal to ero address?
		// TODO: Require that product exists?
		require(uint(Subcategories.Boots) >= _subcategory);
		uint complementId = complements.push(Complement(_productId, _subcategory, _name)) - 1;
		complementToProduct[complementId] = _productId;
		productComplementCount[_productId].increment();
		emit NewComplement(_productId, complementId, _subcategory, _name);
		return complementId;
	}
}