pragma solidity ^0.5.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./../contracts/KibiwooHelperProducts.sol";

/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke

contract TestKibiwooHelperProducts {

    // TODO: Come up with extreme test cases.
    
    /// Obtain the address of the Smart Contract.
    KibiwooHelperProducts kibiwoohelperproducts = 
        KibiwooHelperProducts(
            DeployedAddresses.KibiwooHelperProducts()
        );

    /// The product Id from which we wiil add complements to.
    uint expectedProductId = 0;
    // Complement Id
    uint expectedComplementId = 0;
    uint idProduct1;
    uint idProduct2;
    uint complement1Id;
    uint complement12Id;
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
    /// @param _subcategory Uint that represents the subcategory of the complement.
    /// @param name Name of the complement to be registered.
    /// @return Id of the created complement.
    function registerComplement(
        uint _productId, 
        uint _subcategory, 
        string memory name
    ) 
        public returns(uint) 
    {
        // Add the complement
        uint complementId = kibiwoohelperproducts.addComplement(_productId, _subcategory, name);
        // Add 1 to the expectedProductId. Recall to substract 1 when asserting.
        expectedComplementId++;
        return complementId;
    }

    
    /// @notice Test the registering of a complement.
    function testAddComplement() public {
        // Register a product first.
        string memory name = "TablaSurf";
        uint category = 0;
        idProduct1 = registerProduct(name, category);
        Assert.equal(
            idProduct1, 
            expectedProductId-1, 
            "Registration of product 1 failed. Ids do not match."
        );
        // Add Complements to tabla de surf
        name = "Complement1 Product1";
        uint subcategory = 0;
        complement1Id = registerComplement(idProduct1, subcategory, name);
        Assert.equal(
            complement1Id, 
            expectedComplementId-1, 
            "Registration of complement for product 1 failed. Ids do not match."
        );
        // test values of complement.
        (uint expectedProduct, uint expectedSubcategory, string memory expectedName) = 
            kibiwoohelperproducts.complements(complement1Id);
        Assert.equal(
            name, 
            expectedName, 
            "Name of complement for product 1 not registered correctly."
        );
        Assert.equal(
            subcategory, 
            expectedSubcategory, 
            "Subcategory of complement 1 of product 1 failed."
        );
        Assert.equal(idProduct1, expectedProduct, "Product of complement 1 failed.");
    }


    /// @notice Test the retrieval of storeToProductCount array
    function testStoreProductCount() public {
        // Register product 2
        string memory name = "SkiesFromigal";
        uint category = 2;
        idProduct2 = registerProduct(name, category);
        Assert.equal(
            idProduct2, 
            expectedProductId-1, 
            "Registration of product 2 failed. Ids do not match."
        );
        uint expectedNumProducts = 2;
        // Test that this contract address has 2 products created.
        uint numProducts = kibiwoohelperproducts.storeProductCount(expectedOwner);
        // \x27 is the ASCII hex value for the character `'`
        Assert.equal(
            numProducts, 
            expectedNumProducts, 
            "Number of products for this contract\x27s address is wrong, should be 2."
        );
        // Test that other address has number of Products total to 0.
        numProducts = kibiwoohelperproducts.storeProductCount(
                address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47)
        );
        Assert.equal(0, numProducts, "Number of products of a random address failed. Should be 0.");
        // Test that zero address has number of products 0.
        numProducts = kibiwoohelperproducts.storeProductCount(address(0));
        Assert.equal(0, numProducts, "Number of products of a address 0 failed. Should be 0.");
    }


    /// @notice Test the retrieval of storeToProductCount array
    function testProductComplementCount() public {
        Assert.equal(
            1, 
            kibiwoohelperproducts.productComplementCount(idProduct1), 
            "Number of complements for product 1 failed."
        );
        Assert.equal(
            0, 
            kibiwoohelperproducts.productComplementCount(idProduct2), 
            "Number of complements for product 2 failed."
        );
        // Register another complement for product 1 and one for product 2.
        string memory name = "Complement2 Product1";
        uint subcategory = 0;
        complement12Id = registerComplement(idProduct1, subcategory, name);
        Assert.equal(
            complement12Id, 
            expectedComplementId-1, 
            "Registration of complement 2 for product 1 failed. Ids do not match."
        );
        // test values of complement.
        (uint expectedProduct, uint expectedSubcategory, string memory expectedName) = 
            kibiwoohelperproducts.complements(complement12Id);
        Assert.equal(
            name, 
            expectedName, 
            "Name of complement 2 for product 1 not registered correctly."
        );
        Assert.equal(
            subcategory, 
            expectedSubcategory, 
            "Subcategory of complement 2 of product 1 failed."
        );
        Assert.equal(idProduct1, expectedProduct, "Product of complement 2 failed.");
        // Add Complements to tabla de surf
        name = "Complement1 Product2";
        subcategory = 2;
        complement2Id = registerComplement(idProduct2, subcategory, name);
        Assert.equal(
            complement2Id, 
            expectedComplementId-1, 
            "Registration of complement 1 for product 2 failed. Ids do not match."
        );
        // test values of complement.
        (expectedProduct, expectedSubcategory, expectedName) = 
            kibiwoohelperproducts.complements(complement2Id);
        Assert.equal(
            name, 
            expectedName, 
            "Name of complement 1 for product 2 not registered correctly."
        );
        Assert.equal(
            subcategory, 
            expectedSubcategory, 
            "Subcategory of complement 1 of product 2 failed."
        );
        Assert.equal(idProduct2, expectedProduct, "Product of complement 1 (product 2) failed.");
        // Test again values of ProducComplementCount
        Assert.equal(
            2, 
            kibiwoohelperproducts.productComplementCount(idProduct1), 
            "Number of complements for product 1 failed."
        );
        Assert.equal(
            1, 
            kibiwoohelperproducts.productComplementCount(idProduct2), 
            "Number of complements for product 2 failed."
        );
        // Test that non-existent product has zero complements.
        uint numComplements = kibiwoohelperproducts.productComplementCount(10);
        Assert.equal(0, numComplements, "Number of complements for non-existent product failed.");
    }

    /// @notice Test the retrieval of complementToProduct mapping
    function testComplementToProduct () public {
        Assert.equal(
            kibiwoohelperproducts.complementToProduct(complement1Id), 
            idProduct1, 
            "ComplementToProduct failed for complement 1 of product 1."
        );
        Assert.equal(
            kibiwoohelperproducts.complementToProduct(complement12Id), 
            idProduct1, 
            "ComplementToProduct failed for complement 2 of product 1."
        );
        Assert.equal(
            kibiwoohelperproducts.complementToProduct(complement2Id), 
            idProduct2, 
            "ComplementToProduct failed for complement 1 of product 2."
        );
    }


    /// @notice Test the retrieval of all products of a specific shop or owner
    function testGetProductsByShop () public {
        uint[] memory productsResult = kibiwoohelperproducts.getProductsByShop(expectedOwner);
        Assert.equal(
            2, 
            productsResult.length, 
            "Number of products for this contract\x27s address should be 2."
        );
        Assert.equal(0, productsResult[0], "First product Id of this owner should be 0");
        Assert.equal(1, productsResult[1], "Last product Id of this owner should be 1");
        // Test that other address has number of Products total to 0.
        productsResult = 
            kibiwoohelperproducts.getProductsByShop(
                address(0xa50b4f040acb653735a0d496c34c1b6b5a635e1b21de334fb2427f3e866fbc47)
            );
        Assert.equal(
            0, 
            productsResult.length, 
            "Number of products of a random address failed. Should be 0."
        );
        // Test that zero address has number of products 0.
        productsResult = kibiwoohelperproducts.getProductsByShop(address(0));
        Assert.equal(
            0, 
            productsResult.length, 
            "Number of products of th zero address failed. Should be 0."
        );
    }
}