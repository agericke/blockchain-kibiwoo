pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./../contracts/kibiwoohelperproducts.sol";

/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke

contract TestKibiwooHelperProducts {

	// TODO: Come up with extreme test cases.
	
	/// Obtain the address of the Smart Contract.
	KibiwooHelperProducts kibiwoohelperproducts = KibiwooHelperProducts(DeployedAddresses.KibiwooHelperProducts());

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
		uint id = kibiwoohelperproducts.createNewProduct(name, category);
		expectedProductId++;
		return id;
	}

	/// @notice Test the registering of a complement.
	/// @param _productId The id of the product which to ad a complement to.
	/// @param name Name of the complement to be registered.
	/// @return Id of the created complement.
	function registerComplement (uint _productId, string memory name) public returns(uint) {
		uint complementId = kibiwoohelperproducts.addComplement(_productId, name);
		expectedProductId++;
		return complementId;
	}


	/// @notice Test that a products category is the same as its complements
	/// @param _productId The id of the product.
	/// @param _productId The id of the complement.
	function checkProductandComplementCategory (uint _productId, uint _complementId) public {
		(, , , uint productCategory) = kibiwoohelperproducts.products(_productId);
		(, , , uint complementCategory) = kibiwoohelperproducts.products(_complementId);
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
		(string memory expectedName, , bool expectedIsComplement, uint expectedCategory) = kibiwoohelperproducts.products(complement1Id);
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
		uint numProducts = kibiwoohelperproducts.storeProductCount(expectedOwner);
		// \x27 is the ASCII hex value for the character `'`
		Assert.equal(numProducts, expectedNumProducts, "Number of products for this contract\x27s address is wrong, should be 3.");
		// Test that other address has number of Products total to 0.
		numProducts = kibiwoohelperproducts.storeProductCount(address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47));
		Assert.equal(0, numProducts, "Number of products of a random address failed. Should be 0.");
		// Test that zero address has number of products 0.
		numProducts = kibiwoohelperproducts.storeProductCount(address(0));
		Assert.equal(0, numProducts, "Number of products of a address 0 failed. Should be 0.");
	}


	/// @notice Test the retrieval of complementToProduct mapping
	function testComplementToProduct () public {
		Assert.equal(kibiwoohelperproducts.complementToProduct(complement1Id), idProductWithComplements1, "ComplementToProduct failed for complement 1 of product 1.");
		// Add Complements to tabla de surf
		string memory name = "Complement2 Product1";
		complement1Id = registerComplement(idProductWithComplements1, name);
		Assert.equal(kibiwoohelperproducts.complementToProduct(complement1Id), idProductWithComplements1, "ComplementToProduct failed for complement 2 of product 1.");
		// Add Complements to tabla de surf
		name = "Complement2 Product2";
		complement2Id = registerComplement(idProductWithComplements2, name);
		Assert.equal(kibiwoohelperproducts.complementToProduct(complement2Id), idProductWithComplements2, "ComplementToProduct failed for complement 1 of product 2.");
	}


	/// @notice Test the retrieval of productComplementCount mapping
	function testProductComplementCount () public {
		Assert.equal(2, kibiwoohelperproducts.productComplementCount(idProductWithComplements1), "Number of complements of product 1 do not match.");
		Assert.equal(1, kibiwoohelperproducts.productComplementCount(idProductWithComplements2), "Number of complements of product 2 do not match.");
		Assert.equal(0, kibiwoohelperproducts.productComplementCount(15), "Number of complements of non-existing product do not match.");
	}


	/// @notice Test the retrieval of all products of a specific shop or owner
	function testGetProductsByShop () public {
		uint[] memory productsResult = kibiwoohelperproducts.getProductsByShop(expectedOwner);
		Assert.equal(5, productsResult.length, "Number of products for this contract\x27s address should be 5.");
		Assert.equal(0, productsResult[0], "First product Id of this owner should be 0");
		Assert.equal(4, productsResult[4], "Last product Id of this owner should be 4");
		// Test that other address has number of Products total to 0.
		productsResult = kibiwoohelperproducts.getProductsByShop(address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47));
		Assert.equal(0, productsResult.length, "Number of products of a random address failed. Should be 0.");
		// Test that zero address has number of products 0.
		productsResult = kibiwoohelperproducts.getProductsByShop(address(0));
		Assert.equal(0, productsResult.length, "Number of products of th zero address failed. Should be 0.");
	}
}