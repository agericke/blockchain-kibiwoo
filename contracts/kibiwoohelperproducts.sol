pragma solidity ^0.5.0;

import "./kibiwoomanageproducts.sol";

/// @title A contract that implements some functions for helping Kibiwoo's managing of products
/// @author Álvaro Gericke
contract KibiwooHelperProducts is KibiwooManageProducts {

	/// @notice Withdraws all the balance in the contract back to owner of the contract
	function withdraw() external onlyOwner {
		address payable _owner = address(uint160(owner()));
		_owner.transfer(address(this).balance);
	}

	/// @notice Returns all the products with its complements that are owned by a specific shop.
    /// @param _owner Address of the shop to retrieve the products from it.
    /// @return An array with all the IDs of the products and their complements owned by that shop
	function getProductsByShop (address _owner) external view returns (uint[] memory) {

		uint[] memory productsResult = new uint[](storeProductCount[_owner]);
		// IterAte over all the products and build an array of products
		uint counter = 0;
		for (uint i = 0; i < products.length; i++) {
			if (productToStore[i] == _owner) {
				productsResult[counter] = i;
				counter++;
			}
		}
		return productsResult;
	}
}