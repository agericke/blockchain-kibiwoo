pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./../contracts/kibiwoomanageproducts.sol";

/// @title A tester contract for testing Kibiwoo's managing products solution.
/// @author Álvaro Gericke

contract TestKibiwooManageProducts {

	// TODO: Come up with extreme test cases.
	
	/// Obtain the address of the Smart Contract.
	KibiwooManageProducts kibiwoomanageproducts = KibiwooManageProducts(DeployedAddresses.KibiwooManageProducts());

	/// The product Id from which we wiil add complements to.
	uint expectedProductId = 0;
	uint idProductWithComplements1;
	uint idProductWithComplements2;
	uint complement1Id;
	uint complement2Id;
	address expectedOwner = address(this);

	/// @notice Test the registering of a product.
	/// @param name Name of the product to be registered.
	/// @param category Number that represents the category to be registered.
	/// @return Id of the created product.
	function registerProduct (string memory name, uint category) public returns(uint) {
		uint id = kibiwoomanageproducts.createNewProduct(name, category);
		// Add 1 to the expectedProductId. Recall to substract 1 when asserting.
		expectedProductId++;
		return id;
	}

	/// @notice Test the registering of a complement.
	/// @param _productId The id of the product which to ad a complement to.
	/// @param name Name of the complement to be registered.
	/// @return Id of the created complement.
	function registerComplement (uint _productId, string memory name) public returns(uint) {
		// Add the complement
		uint complementId = kibiwoomanageproducts.addComplement(_productId, name);
		// Add 1 to the expectedProductId. Recall to substract 1 when asserting.
		expectedProductId++;
		return complementId;
	}

	// /// @notice BeforeAll hook for registering several products.
	// function BeforeAll() public {
	// 	/// Register first product
	// 	string memory name = "TablaSurf";
	// 	uint category = 0;
	// 	idProductWithComplements1 = registerProduct(name, category);
	// 	Assert.equal(idProductWithComplements1, expectedProductId-1, "Registration of product 1 failed. Ids do not match.");
	// 	// Register product 2
	// 	name = "SkiesFromigal";
	// 	category = 2;
	// 	idProductWithComplements2 = registerProduct(name, category);
	// 	Assert.equal(idProductWithComplements2, expectedProductId-1, "Registration of product 2 failed. Ids do not match.");
	// }

	/// @notice Test that a products category is the same as its complements
	/// @param _productId The id of the product.
	/// @param _productId The id of the complement.
	function checkProductandComplementCategory (uint _productId, uint _complementId) public {
		(, , , uint productCategory) = kibiwoomanageproducts.products(_productId);
		(, , , uint complementCategory) = kibiwoomanageproducts.products(_complementId);
		Assert.equal(productCategory, complementCategory, "Product category and complement category do not match.");
	}

	
	/// @notice Test the registering of a complement.
	function testAddComplement () public {
		string memory name = "TablaSurf";
		uint category = 0;
		idProductWithComplements1 = registerProduct(name, category);
		Assert.equal(idProductWithComplements1, expectedProductId-1, "Registration of product 1 failed. Ids do not match.");
		// Add Complements to tabla de surf
		name = "Complement1 Product1";
		complement1Id = registerComplement(idProductWithComplements1, name);
		Assert.equal(complement1Id, expectedProductId-1, "Registration of complement for product 1 failed. Ids do not match.");
		// test values of complement.
		(string memory expectedName, , bool expectedIsComplement, uint expectedCategory) = kibiwoomanageproducts.products(complement1Id);
		Assert.equal(name, expectedName, "Name of complement for product 1 not registered correctly.");
		Assert.equal(true, expectedIsComplement, "isComplement field of complement for product 1 not registered correctly.");
		// Check category of product is equal to the one from 
		checkProductandComplementCategory(idProductWithComplements1, expectedCategory);
	}

	/// @notice Test the retireval of storeToProductCount array
	function testStoreProductCount () public {
		// Register product 2
		string memory name = "SkiesFromigal";
		uint category = 2;
		idProductWithComplements2 = registerProduct(name, category);
		Assert.equal(idProductWithComplements2, expectedProductId-1, "Registration of product 2 failed. Ids do not match.");
		uint expectedNumProducts = 3;
		// Test that this contract address has 3 products created. (2 plus 1 complement.)
		uint numProducts = kibiwoomanageproducts.storeProductCount(expectedOwner);
		// \x27 is the ASCII hex value for the character `'`
		Assert.equal(numProducts, expectedNumProducts, "Number of products for this contract\x27s address is wrong, should be 3.");
		// Test that other address has number of Products total to 0.
		numProducts = kibiwoomanageproducts.storeProductCount(address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47));
		Assert.equal(0, numProducts, "Number of products of a random address failed. Should be 0.");
		// Test that zero address has number of products 0.
		numProducts = kibiwoomanageproducts.storeProductCount(address(0));
		Assert.equal(0, numProducts, "Number of products of a address 0 failed. Should be 0.");
	}

	/// @notice Test the retrieval of complementToProduct mapping
	function testComplementToProduct () public {
		Assert.equal(kibiwoomanageproducts.complementToProduct(complement1Id), idProductWithComplements1, "ComplementToProduct failed for complement 1 of product 1.");
		// Add Complements to tabla de surf
		string memory name = "Complement2 Product1";
		complement1Id = registerComplement(idProductWithComplements1, name);
		Assert.equal(kibiwoomanageproducts.complementToProduct(complement1Id), idProductWithComplements1, "ComplementToProduct failed for complement 2 of product 1.");
		// Add Complements to tabla de surf
		name = "Complement2 Product2";
		complement2Id = registerComplement(idProductWithComplements2, name);
		Assert.equal(kibiwoomanageproducts.complementToProduct(complement2Id), idProductWithComplements2, "ComplementToProduct failed for complement 1 of product 2.");
	}

	/// @notice Test the retrieval of productComplementCount mapping
	function testProductComplementCount () public {
		Assert.equal(2, kibiwoomanageproducts.productComplementCount(idProductWithComplements1), "Number of complements of product 1 do not match.");
		Assert.equal(1, kibiwoomanageproducts.productComplementCount(idProductWithComplements2), "Number of complements of product 2 do not match.");
		Assert.equal(0, kibiwoomanageproducts.productComplementCount(15), "Number of complements of non-existing product do not match.");
	}
}