/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke
const chai = require('chai');
const BN = web3.utils.BN;
// Enable and inject BN dependency
chai.use(require('chai-bn')(BN));
const expect = chai.expect;

//const {expect} = require('chai');

const Kibiwoo = artifacts.require("Kibiwoo.sol");

contract("Kibiwoo", async ([kibiwooOwner, ...accounts]) => {

    let kibiwooInstance;

    beforeEach("setup contract for each test.", async function () {
        kibiwooInstance = await Kibiwoo.new();
    })
    
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
                ).to.be.bignumber.is.at.most(web3.utils.toBN(0));

                await kibiwooInstance.sendTransaction({
                    from: accounts[2],
                    value: web3.utils.toBN(3e+18)
                });
                
                balance = await web3.eth.getBalance(kibiwooInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    "Contract did not receive ether."
                ).to.be.bignumber.is.at.most(web3.utils.toBN(3e+18));
            });
        }
    );

    describe("Test functions for registering a product.", async () => {

        // it("Test user can register a product.", async () => {
        //     // Register product 1
        //     let name = "TablaSurf";
        //     let category = 0;
        //     let id = registerProduct(name, category);
        //     Assert.equal(id, expectedProductId-1, "Registration of product 1 failed. Ids do not match.");
        //     // test values of product.
        //     (, uint expectedCategory, string memory expectedName) = kibiwooregisterproducts.products(id);
        //     Assert.equal(name, expectedName, "Name of product 1 not registered correctly.");
        //     Assert.equal(category, expectedCategory, "Category of product 1 not registered correctly.");

        //     // Register product 2
        //     name = "SkiesFromigal";
        //     category = 2;
        //     id = registerProduct(name, category);
        //     Assert.equal(id, expectedProductId-1, "Registration of product 2 failed. Ids do not match.");
        //     (, expectedCategory, expectedName) = kibiwooregisterproducts.products(id);
        //     Assert.equal(name, expectedName, "Name of product 2 not registered correctly.");
        //     Assert.equal(category, expectedCategory, "Category of product 2 not registered correctly.");
        //     // TODO: Test invalid arguments, specially categoriescd Do
        // })
    });
});

