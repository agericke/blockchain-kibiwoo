pragma solidity ^0.5.2;

import "truffle/Assert.sol";
/// When running tests, Truffle will dpeloy a fresh instance of the contract being tested to the Blockchain.
/// 	This Smart Contract gets the adress of the deployed contract.
import "truffle/DeployedAddresses.sol";
import "./../contracts/kibiwooregisterproducts.sol";

/// @title A tester contarct for testing Kibiwoo's register products solution.
/// @author Álvaro Gericke

contract TestKibiwooRegisterProducts {

	/// Obtain the address of the Smart Contract.
	KibiwooRegisterProducts kibiwooregisterproducts = KibiwooRegisterProducts(DeployedAddresses.KibiwooRegisterProducts());

	/// Number of times we have registered a product that allows us to keep track of the product Id.
	uint expectedProductId = 0;
	address expectedOwner = address(this);
	
	/// @notice Test the registering of a product.
	/// @param name Name of the product to be registered.
	/// @param category Number that represents the category to be registered.
	/// @return Id of the created product.
	function registerProduct (string memory name, uint category) public returns(uint) {
		uint id = kibiwooregisterproducts.createNewProduct(name, category);
		// Add 1 to the expectedProductId. Recall to substract 1 when asserting.
		expectedProductId++;
		return id;
	}

	/// @notice Test if registering of products works correctly.
	function testUserCanRegisterProducts () public {
		// Register product 1
		string memory name = "TablaSurf";
		uint category = 0;
		uint id = registerProduct(name, category);
		Assert.equal(id, expectedProductId-1, "Registration of product 1 failed. Ids do not match.");
		// test values of product.
		(string memory expectedName, , bool expectedIsComplement, uint expectedCategory) = kibiwooregisterproducts.products(id);
		Assert.equal(name, expectedName, "Name of product 1 not registered correctly.");
		Assert.equal(category, expectedCategory, "Category of product 1 not registered correctly.");
		Assert.equal(false, expectedIsComplement, "isComplement field of product 1 not registered correctly.");

		// Register product 2
		name = "SkiesFromigal";
		category = 2;
		id = registerProduct(name, category);
		Assert.equal(id, expectedProductId-1, "Registration of product 2 failed. Ids do not match.");
		(expectedName, , expectedIsComplement, expectedCategory) = kibiwooregisterproducts.products(id);
		Assert.equal(name, expectedName, "Name of product 2 not registered correctly.");
		Assert.equal(category, expectedCategory, "Category of product 2 not registered correctly.");
		Assert.equal(false, expectedIsComplement, "isComplement field of product 2 not registered correctly.");
		// TODO: Test invalid arguments, specially categories
	}
	
	/// @notice Test the retireval of productToStore array.
	function testProductToStoreVar () public {
		address p1Owner = kibiwooregisterproducts.productToStore(0);
		address p2Owner = kibiwooregisterproducts.productToStore(1);
		// Test that owner of created products are stored correctly
		Assert.equal(p1Owner, expectedOwner, "Owner of product 1 failed. Addresses do not match.");
		Assert.equal(p2Owner, expectedOwner, "Owner of product 2 failed. Addresses do not match.");

		// Test that owner of non-created products have address 0x0.
		address pnonOwner = kibiwooregisterproducts.productToStore(30);
		Assert.equal(pnonOwner, address(0), "Owner of a non created product failed. Address should be 0x0.");
	}

	/// @notice Test the retireval of storeToProductCount array
	function testStoreProductCount () public {
		log0(bytes32("Testing testStoreProductCount"));
		uint expectedNumProducts = 2;
		// Test that this contract address has 2 products created.
		uint numProducts = kibiwooregisterproducts.storeProductCount(expectedOwner);
		// \x27 is the ASCII hex value for the character `'`
		Assert.equal(numProducts, expectedNumProducts, "Number of products for this contract\x27s address is wrong, should be 2.");
		// Test that other address has number of Products total to 0.
		numProducts = kibiwooregisterproducts.storeProductCount(address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47));
		Assert.equal(0, numProducts, "Number of products of a random address failed. Should be 0.");
		// Test that zero address has number of products 0.
		numProducts = kibiwooregisterproducts.storeProductCount(address(0));
		Assert.equal(0, numProducts, "Number of products of a address 0 failed. Should be 0.");
	}
	// function testGetOwnersAddressByProductID () public {
		
	// 	//address owner = kibiwoo._owners(expectedProductId);

	// 	//Assert.equal(owner, expectedOwner, "Owner of the expected product does not match.");
	// }

	// function testGetOwnerAdressByProductIdInArray() public {

	// 	//address[20] memory owners = kibiwoo.getOwners();

	// 	//Assert.equal(owners[expectedProductId], expectedOwner, "Owner of th expected product should be this contract");
	// }
	
}