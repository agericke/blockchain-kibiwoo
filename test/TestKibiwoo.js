/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke
const chai = require('chai');
const BN = require('bn.js');
// Enable and inject BN dependency
chai.use(require('chai-bn')(BN));
const expect = chai.expect;

const Kibiwoo = artifacts.require("Kibiwoo.sol");

contract("Kibiwoo", async ([kibiwooOwner, shop1, shop2, customer1, customer2, ...accounts]) => {

    let kibiwooInstance;

    beforeEach("setup contract for each test.", async function () {
        kibiwooInstance = await Kibiwoo.new();
    });
    
    describe(
        "#Initial checks regarding initial set-up and general Smart contract configuration", 
        async () => {
        
            it("Check Owner is first ganache account.", async () => {
                
                expect(
                    await kibiwooInstance.kibiwooAdmin.call(), 
                    "Kibiwoo Owner should be first account."
                ).to.equal(kibiwooOwner);
            });

            it("Check if owner is equal to kibiwooAdmin address.", async () => {
                let owner = await kibiwooInstance.owner.call();
                let kibiwooAdmin = await kibiwooInstance.kibiwooAdmin.call();
                expect(
                    kibiwooAdmin, 
                    "Kibiwoo Administrator and owner do not coincide."
                ).to.equal(owner);
            });

            it("Check Smart Contract can receive ether.", async () => {
                
                let balance = await web3.eth.getBalance(kibiwooInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    "Contract does not have 0 balance."
                ).to.be.bignumber.equal(web3.utils.toBN(0));

                await kibiwooInstance.sendTransaction({
                    from: accounts[0],
                    value: web3.utils.toBN(3e+18)
                });
                
                balance = await web3.eth.getBalance(kibiwooInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    "Contract did not receive ether."
                ).to.be.bignumber.equal(web3.utils.toBN(3e+18));
            });
        }
    );

    describe("#Test functions for registering a product.", async () => {

        let kibiwooObjVars = {};

        beforeEach("Create help variables for testing.", function () {
            kibiwooObjVars.expectedId = 0;
            kibiwooObjVars.numProductsShop1 = 0;
            kibiwooObjVars.numProductsShop2 = 0;
        });

        async function checkIdProduct(productId, kibiwooObj) {
            expect(
                web3.utils.toBN(productId), 
                "Product id value in event wrong"
            ).to.be.bignumber.equal(web3.utils.toBN(kibiwooObj.expectedId));
            kibiwooObj.expectedId++;
        }

        it("Check registering a product emits a new product event with correct values.", async () => {
            // Register product 1
            let name = "TablaSurf";
            let category = 0;
            let receipt = await kibiwooInstance.createNewProduct(name, category, {from: shop1});
            expect(
                web3.utils.toBN(receipt.logs.length), 
                "an event wasn't triggered"
            ).to.be.bignumber.equal(web3.utils.toBN(1));
            expect(receipt.logs[0].event, "the event type is correct").to.be.equal("NewProduct");
            await checkIdProduct(receipt.logs[0].args.id, kibiwooObjVars);
            expect(
                web3.utils.toBN(receipt.logs[0].args.category), 
                "Product category value in event wrong"
            ).to.be.bignumber.equal(web3.utils.toBN(category));
            expect(
                receipt.logs[0].args.name, 
                "Product name value in event wrong"
            ).to.equal(name);
            //() = kibiwooInstance.products(0).call();
            // expect(
            //     web3.utils.toBN(id), 
            //     "Id for product 1 should be 0."
            // ).to.be.bignumber.is.at.most(web3.utils.toBN(expectedId));

            // test values of product.
            // (, uint expectedCategory, string memory expectedName) = kibiwooregisterproducts.products(id);
            // Assert.equal(name, expectedName, "Name of product 1 not registered correctly.");
            // Assert.equal(category, expectedCategory, "Category of product 1 not registered correctly.");

            // // Register product 2
            // name = "SkiesFromigal";
            // category = 2;
            // id = registerProduct(name, category);
            // Assert.equal(id, expectedProductId-1, "Registration of product 2 failed. Ids do not match.");
            // (, expectedCategory, expectedName) = kibiwooregisterproducts.products(id);
            // Assert.equal(name, expectedName, "Name of product 2 not registered correctly.");
            // Assert.equal(category, expectedCategory, "Category of product 2 not registered correctly.");
            // // TODO: Test invalid arguments, specially categoriescd Do
        })
    });
});

