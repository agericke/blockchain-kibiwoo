/// @title A tester contract for testing Kibiwoo's helper products solidity contract.
/// @author Álvaro Gericke
const { constants, expectEvent, expectRevert } = require('openzeppelin-test-helpers');
const {expect} = require('chai');
const { ZERO_ADDRESS } = constants;

const BigNumber = require("bignumber.js");

const Kibiwoo = artifacts.require("Kibiwoo.sol");

contract("Kibiwoo", function ([kibiwooOwner, shop1, shop2, customer1, customer2, ...accounts]) {

    beforeEach(async function () {
        this.contractName = "KibiwooProductsTFM";
        this.contractSymbol = "KBW";
        this.kibiwooInstance = await Kibiwoo.new(this.contractName, this.contractSymbol);
    });
    
    describe(
        '#Initial checks regarding initial set-up and general Smart contract configuration', 
        function () {
        
            it('Check Owner is first ganache account.', async function () {
                expect(
                    await this.kibiwooInstance.getAdmin.call(), 
                    'Kibiwoo Owner should be first account.'
                ).to.equal(kibiwooOwner);
            });

            it('Check if owner is equal to kibiwooAdmin address.', async function () {
                let owner = await this.kibiwooInstance.owner.call();
                let kibiwooAdmin = await this.kibiwooInstance.getAdmin.call();
                expect(
                    kibiwooAdmin, 
                    'Kibiwoo Administrator and owner do not coincide.'
                ).to.equal(owner);
            });

            it('Check Smart Contract can receive ether.', async function () {
                
                let balance = await web3.eth.getBalance(this.kibiwooInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    'Contract does not have 0 balance.'
                ).to.be.bignumber.equal(web3.utils.toBN(0));

                await this.kibiwooInstance.sendTransaction({
                    from: accounts[0],
                    value: web3.utils.toBN(3e+18)
                });
                
                balance = await web3.eth.getBalance(this.kibiwooInstance.address);
                
                expect(
                    web3.utils.toBN(balance), 
                    'Contract did not receive ether.'
                ).to.be.bignumber.equal(web3.utils.toBN(3e+18));
            });
        }
    );

    describe('#Test function for registering a product.', function () {

        it('Reverts with negative category value.', async function () {
            let name = 'TablaSurf';
            let category = -1;
            await expectRevert(
                this.kibiwooInstance.createNewProduct(name, category, {from: shop1}), 
                'Invalid category.'
            );
        });

        it('Reverts with very high category value.', async function () {
            let name = 'TablaSurf';
            let category = 5;
            await expectRevert(
                this.kibiwooInstance.createNewProduct(name, category, {from: shop1}), 
                'Invalid category.'
            );
        });

        it('Throws when querying a non-existing product.', async function () {
            await expectRevert.assertion(this.kibiwooInstance.products(5));
        });

        it('Throws when introducing an invalid name value.', async function () {
            try {
                await this.kibiwooInstance.createNewProduct(5, 0, {from: shop1})
                assert.fail();
            } catch (err) {
                assert.ok(/invalid string/.test(err.message));
            }
        });

        context('With valid arguments', function () {
            beforeEach('Register a product and store logs.', async function () {
                this.expectedId = new web3.utils.BN(0);
                this.name = 'TablaSurf';
                this.category = new web3.utils.BN(0);  
                ({ logs: this.logs } = await 
                    this.kibiwooInstance.createNewProduct(this.name, this.category, {from: shop1}));
                this.expectedContractAddress = await 
                    this.kibiwooInstance.getContractBookingAddress(this.expectedId);
            });

            it('Registering a product emits NewProduct and Transfer event.', async function () {
                expectEvent.inLogs(
                    this.logs, 
                    'Transfer', 
                    {from: ZERO_ADDRESS, to: shop1, tokenId: this.expectedId}
                );
                expectEvent.inLogs(
                    this.logs,
                    'NewProduct',
                    {
                        bookingContractAddress: this.expectedContractAddress, 
                        id: this.expectedId, 
                        category: this.category, 
                        name: this.name
                    }
                );
            });

            it('Check products array values are correct.', async function () {
                let product = await this.kibiwooInstance.products(0);
                expect(
                    product.category, 
                    'Product\'s Category does not match.'
                ).to.be.bignumber.equal(web3.utils.toBN(this.category));
                expect(
                    web3.utils.toBN(product.min_rent_time), 
                    'Product\'s Minimum Renting Time does not match.'
                ).to.be.bignumber.equal(web3.utils.toBN(3600));
                expect(product.name, 'Product\'s Name does not match.').to.equal(this.name);
            });
        });
    });

    describe('#Test contract mapping variables.', function () {

        describe('#Test _tokenOwner mapping.', function () {

            beforeEach('Register several products.', async function () {
                // TODO: generalize this function to store logs so that id of products is extracted from there.
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});
            });

            it('Reverts when querying non existing token.', async function () {
                await expectRevert(
                    this.kibiwooInstance.ownerOf(10),
                    "ERC721: owner query for nonexistent token"
                );
            });

            it('Throws when querying a non existing product.', async function () {
                await expectRevert.assertion(this.kibiwooInstance.products(10));
            });

            it('Throws when querying a negative index for products array.', async function () {
                await expectRevert.assertion(this.kibiwooInstance.products(-1));
            });

            context("With valid arguments.", function () {

                it('Check correct owners.', async function () {
                    expect(await this.kibiwooInstance.ownerOf(0)).to.equal(shop1);
                    expect(await this.kibiwooInstance.ownerOf(1)).to.equal(shop1);
                    expect(await this.kibiwooInstance.ownerOf(2)).to.equal(shop1);
                    expect(await this.kibiwooInstance.ownerOf(3)).to.equal(shop2);
                    expect(await this.kibiwooInstance.ownerOf(4)).to.equal(shop2);
                });

                it('Check new product has correct owner.', async function () {
                    await this.kibiwooInstance.createNewProduct('Producto6', 0, {from: shop1});
                    expect(await this.kibiwooInstance.ownerOf(5)).to.equal(shop1); 
                });

            });
        });

        describe('#Test _ownedTokensCounts mapping.', function () {

            beforeEach('Register several products.', async function () {
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});
            });

            it('Reverts when querying balance for zero address.', async function () {
                await expectRevert(
                    this.kibiwooInstance.balanceOf(ZERO_ADDRESS),
                    "ERC721: balance query for the zero address"
                );
            });

            context("With valid arguments.", function () {

                it('Zero balance for address with no tokens.', async function () {
                    expect(
                        await this.kibiwooInstance.balanceOf(customer1)
                    ).to.be.bignumber.equal(new web3.utils.BN(0));
                });

                it('Correct balance for addreses with tokens.', async function () {
                    expect(
                        await this.kibiwooInstance.balanceOf(shop1)
                    ).to.be.bignumber.equal(new web3.utils.BN(3));
                    expect(
                        await this.kibiwooInstance.balanceOf(shop2)
                    ).to.be.bignumber.equal(new web3.utils.BN(2));
                });

                it('Balance increments by one after registering new product.', async function () {
                    // TODO: Found another implementation of BN that works correctly.
                    // issue Bn.js: https://stackoverflow.com/questions/54604859/calling-web3-utils-bn-add-gives-error-cannot-create-property-negative-on-numb?rq=1
                    //let beforeBalance = await this.kibiwooInstance.balanceOf(shop1);
                    await this.kibiwooInstance.createNewProduct('Producto6', 0, {from: shop1});
                    expect(
                        await this.kibiwooInstance.balanceOf(shop1)
                    ).to.be.bignumber.equal(web3.utils.toBN(4));
                });
                
            });
        });

        describe('#Test token to contract address mapping variable', function () {

            it('Reverts when querying non existing token.', async function () {
                await expectRevert(
                    this.kibiwooInstance.getContractBookingAddress(10),
                    "ERC721: contract booking address query for nonexistent token."
                );
            });

            context("With valid arguments.", function () {

                 beforeEach('Register several products.', async function () {
                    await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                });

                it('Check that it returns correct values.', async function () {
                    let contractAddress = await this.kibiwooInstance.getContractBookingAddress(0);
                    expect(
                        await this.kibiwooInstance.getContractBookingAddress(0)
                    ).to.equal(contractAddress);
                });
            });
        });
    });

    describe('#Test function for registering a complement.', function () {

        beforeEach("Register a product.", async function () {
            await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
            await this.kibiwooInstance.createNewProduct("Bicicleta", 1, {from: shop2});
        });

        context("Revert cases", function () {

            it(
                "Reverts when registering a complement for a non-existing product", 
                async function () {
                    let productId = 5;
                    let subcategory = 0;
                    let name = "Complemento surf";
                    await expectRevert(
                        this.kibiwooInstance.addComplement(
                            productId, 
                            subcategory, 
                            name, 
                            {from: shop1}
                        ),
                        "ERC721: owner query for nonexistent token"
                    );
                }
            );

            it(
                "Reverts when registering a product without being the owner of the product.", 
                async function () {
                    let productId = 0;
                    let subcategory = 0;
                    let name = "Complemento surf";
                    await expectRevert(
                        this.kibiwooInstance.addComplement(
                            productId,
                            subcategory,
                            name,
                            {from: shop2}
                        ),
                        "ERC721: Action restricted to owner of product."
                    );
                }
            );

            it("Reverts when introducing a very high subcategory value.", async function () {
                let productId = 0;
                let subcategory = 5;
                let name = "Complemento surf";
                expectRevert(
                    this.kibiwooInstance.addComplement(productId, subcategory, name, {from: shop1}),
                    "Invalid subcategory."
                );
            });

            it("Reverts when introducing a negative subcategory value.", async function () {
                let productId = 0;
                let subcategory = -1;
                let name = "Complemento surf";
                expectRevert(
                    this.kibiwooInstance.addComplement(productId, subcategory, name, {from: shop1}),
                    "Invalid subcategory."
                );
            });

            it('Throws when querying a non-existent complement', async function () {
                await expectRevert.assertion(this.kibiwooInstance.complements(5));
            });

            it('Throws when introducing an invalid name value.', async function () {
                try {
                    await this.kibiwooInstance.addComplement(5, 0, 2, {from: shop1})
                    assert.fail();
                } catch (err) {
                    assert.ok(/invalid string/.test(err.message));
                }
            });
        });

        context("With valid arguments", function () {
                
            beforeEach('Register a complement and store logs.', async function () {
                this.expectedId = new web3.utils.BN(0);
                this.name = 'TablaSurf';
                this.subcategory = new web3.utils.BN(0);  
                ({ logs: this.logs } = await this.kibiwooInstance.addComplement(
                    this.expectedId, 
                    this.subcategory, 
                    this.name, 
                    {from: shop1}
                ));
            });

            it('Registering a complement emits NewComplement event.', async function () {
                expectEvent.inLogs(
                    this.logs, 
                    'NewComplement', 
                    {
                        tokenId: this.expectedId, 
                        complementId: new web3.utils.BN(0), 
                        subcategory: this.subcategory,
                        name: this.name
                    }
                );
            });

            it('Check complement array values are correct.', async function () {
                let complement = await this.kibiwooInstance.complements(0);
                expect(
                    complement.productId, 
                    'Complement\'s productId does not match.'
                ).to.be.bignumber.equal(this.expectedId);
                expect(
                    complement.subcategory, 
                    'Complement\'s subcategory does not match.'
                ).to.be.bignumber.equal(this.subcategory);
                expect(
                    complement.name, 
                    'Commplement\'s Name does not match.'
                ).to.equal(this.name);
            });
        });
    });

    describe('#Test contract mapping variables for complements.', function () {

        describe('#Test _complementToProduct mapping.', function () {

            // TODO: mapping initializes to zero, so complements not created will be initialized to zero always,
            // so this way the complementToProduct will need to be handled differently.
            it(
                'Reverts when querying product for a non-existing complement.', 
                async function () {
                    await expectRevert(
                        this.kibiwooInstance.getProductOfComplement(10),
                        "Querying non-existent complement."
                    );
                }
            );

            it(
                'Reverts when querying product for a nonegative complement Id.', 
                async function () {
                    await expectRevert(
                        this.kibiwooInstance.getProductOfComplement(-1),
                        "Querying non-existent complement."
                    );
                }
            );

            context("With valid arguments.", function () {
                beforeEach('Register several products and complements.', async function () {
                    // TODO: generalize this function to store logs so that id of products is extracted from there.
                    await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                    await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                    await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                    await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});
                    await this.kibiwooInstance.addComplement(0, 0, "Comp1P0", {from: shop1});
                    await this.kibiwooInstance.addComplement(0, 1, "Comp2P0", {from: shop1});
                    await this.kibiwooInstance.addComplement(2, 2, "Comp1P2", {from: shop2});
                });

                it("Check productsId for complements are correct", async function () {
                    expect(
                        await this.kibiwooInstance.getProductOfComplement(0)
                    ).to.be.bignumber.equal(new web3.utils.BN(0));
                    expect(
                        await this.kibiwooInstance.getProductOfComplement(1)
                    ).to.be.bignumber.equal(new web3.utils.BN(0));
                    expect(
                        await this.kibiwooInstance.getProductOfComplement(2)
                    ).to.be.bignumber.equal(new web3.utils.BN(2));
                });
            });

        });

        describe('#Test _tokenComplementCount mapping.', function () {

            beforeEach('Register several products and complements.', async function () {
                // TODO: generalize this function to store logs so that id of products is extracted from there.
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                await this.kibiwooInstance.addComplement(0, 0, "Complemento1P0", {from: shop1});
                await this.kibiwooInstance.addComplement(0, 1, "Complemento2P0", {from: shop1});
                await this.kibiwooInstance.addComplement(2, 2, "Complemento1P3", {from: shop2});
            });

            it('Reverts when querying with negative Id.', async function () {
                await expectRevert(
                    this.kibiwooInstance.getComplementsCount(-1),
                    "ERC721: complements count query for nonexistent token."
                );
            });

            it('Reverts when querying with invalid Id.', async function () {
                await expectRevert(
                    this.kibiwooInstance.getComplementsCount(10),
                    "ERC721: complements count query for nonexistent token."
                );
            });

            context("With valid arguments.", function () {

                it('Zero complements for product with no complements.', async function () {
                    expect(
                        await this.kibiwooInstance.getComplementsCount(1)
                    ).to.be.bignumber.equal(new web3.utils.BN(0));
                });

                it('Correct balance for products with complements.', async function () {
                    expect(
                        await this.kibiwooInstance.getComplementsCount(0)
                    ).to.be.bignumber.equal(new web3.utils.BN(2));
                    expect(
                        await this.kibiwooInstance.getComplementsCount(2)
                    ).to.be.bignumber.equal(new web3.utils.BN(1));
                });

                it(
                    'Nº complement increments by one after addinf a complement new product.', 
                    async function () {
                        // TODO: Found another implementation of BN that works correctly.
                        // issue Bn.js: https://stackoverflow.com/questions/54604859/calling-web3-utils-bn-add-gives-error-cannot-create-property-negative-on-numb?rq=1
                        //let beforeBalance = await this.kibiwooInstance.balanceOf(shop1);
                        await this.kibiwooInstance.addComplement(0, 2, 'C3P0', {from: shop1});
                        expect(
                            await this.kibiwooInstance.getComplementsCount(0)
                        ).to.be.bignumber.equal(web3.utils.toBN(3));
                    }
                );
                
            });
        });
    });

    describe('#Test function for obtaining all products for an address.', function () {

        it("Reverts if calling with ZERO_ADDRESS as parameter.", async function () {
            await expectRevert(
                this.kibiwooInstance.getProductsByShop(ZERO_ADDRESS),
                "ERC721: balance query for the zero address"
            );
        });

        it("Reverts if address has no products (0 balance)", async function () {
            await expectRevert(
                this.kibiwooInstance.getProductsByShop(shop1),
                "ERC721: Querying products for a store with 0 products."
            );
        });

        context("With valid arguments", function () {

            beforeEach('Register several products.', async function () {
                // TODO: generalize this function to store logs so that id of products is extracted from there.
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto4', 2, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});

                this.shop1Prds = [new web3.utils.BN(0), new web3.utils.BN(1), new web3.utils.BN(3)];
                this.shop2Prds = [new web3.utils.BN(2), new web3.utils.BN(4)];
            });

            // TODO: Change way of testing for a statement that tests deep equliaty all bignumber
            //  objects of the array and works. Still not a correct implementation. See the following
            //  issue: https://github.com/OpenZeppelin/chai-bn/issues/5
            it("Check correct return values", async function () {
                let shop1Products = await this.kibiwooInstance.getProductsByShop(shop1);
                await expect(shop1Products).to.have.deep.lengthOf(this.shop1Prds.length);
                for (let i = 0; i < shop1Products.length; i++) {
                    expect(shop1Products[i]).to.be.bignumber.equal(this.shop1Prds[i]);
                }
                
                let shop2Products = await this.kibiwooInstance.getProductsByShop(shop2);
                await expect(shop2Products).to.have.deep.lengthOf(this.shop2Prds.length);
                for (let i = 0; i < shop2Products.length; i++) {
                    expect(shop2Products[i]).to.be.bignumber.equal(this.shop2Prds[i]);
                }
            })
        });
    });

    describe('#Test function for obtaining total number of products.', function () {

        beforeEach('Register several products.', async function () {
            // TODO: generalize this function to store logs so that id of products is extracted from there.
            await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
            await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});
        });

        it('Check correct value after registering several products', async function () {
            expect(
                await this.kibiwooInstance.getProductsCount()
            ).to.be.bignumber.equal(web3.utils.toBN(5));
        });

        it('Check that number increments by one after registering new product', async function () {
            
            ini_number = await this.kibiwooInstance.getProductsCount();
            await this.kibiwooInstance.createNewProduct('Producto6', 2, {from: shop1});
            fin_number = await this.kibiwooInstance.getProductsCount();
            expected_number = ini_number.toNumber() + 1;
            expect(fin_number).to.be.bignumber.equal(web3.utils.toBN(expected_number));
        });
    });

    describe('#Test name and symbol variables from ERC721 Metadata extension', function () {

        it('Check name and symbol of Metadata Info.', async function () {
            expect(
                await this.kibiwooInstance.name.call(), 
                'Kibiwoo Contract name does not match.'
            ).to.equal(this.contractName);

            expect(
                await this.kibiwooInstance.symbol.call(),
                'Kibiwoo Symbol does not match.'
            ).to.equal(this.contractSymbol);
        });
    });

    describe('#Test URI Metadata creation for a product', function () {
        
        it('Reverts if setting an URI for a non-existant product.', async function () {
            let id = 50;
            await expectRevert(
                this.kibiwooInstance.tokenURI(id, {from: shop1}), 
                'ERC721Metadata: URI query for nonexistent token'
            );
        });

        context('With valid arguments', function () {

            beforeEach('Register several products.', async function () {
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});
            });

            it('Query the URI for several products', async function() {
                let expectedURI = 'http://127.0.0.1:7545/product-page'
                expect(await this.kibiwooInstance.tokenURI(0)).to.equal(expectedURI);
                expect(await this.kibiwooInstance.tokenURI(4)).to.equal(expectedURI);
            })
        });
    });

    describe('#Test getContractBookingAddress function', function() {

        it('Reverts if querying a contract address for a non-existant product.', async function () {
            let id = 50;
            await expectRevert(
                this.kibiwooInstance.getContractBookingAddress(id, {from: shop1}), 
                'ERC721: contract booking address query for nonexistent token.'
            );
        });

        context('With valid arguments', function () {

            beforeEach('Register several products.', async function () {
                this.expectedId = new web3.utils.BN(0);
                this.name = 'TablaSurf';
                this.category = new web3.utils.BN(0);  
                
                ({ logs: this.logs } = await 
                    this.kibiwooInstance.createNewProduct(this.name, this.category, {from: shop1}));
                this.contractAddress1 = this.logs[1].args["bookingContractAddress"];
                
                ({ logs: this.logs } = await 
                    this.kibiwooInstance.createNewProduct(this.name, 1, {from: shop1}));
                this.contractAddress2 = this.logs[1].args["bookingContractAddress"];
                
            });

            it('Check value of contractAddress to tokenId are correct', async function() {
                expect(
                    this.contractAddress1
                ).to.equal(await this.kibiwooInstance.getContractBookingAddress(0));
                expect(
                    this.contractAddress2
                ).to.equal(await this.kibiwooInstance.getContractBookingAddress(1));
            })
        });
    });

    describe('#Test booking functionality of smart contract.', function () {
        
        beforeEach('Register several products.', async function () {
            // TODO: generalize this function to store logs so that id of products is extracted from there.
            await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
            await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
            await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});

            this.start1 = 1000+5*24*3600;
            this.stop1 = 1000+20*24*3600;
            this.start2 = 1000+30*24*3600;
            this.stop2 = 1000+35*24*3600;
        });

        describe('#Test book function.', function () {

            it('Reverts if booking a non-existent product.', async function () {

                await expectRevert(
                    this.kibiwooInstance.book(10, 1000, 5000, {from: customer1}), 
                    "ERC721: booking query for nonexistent token."
                );
            });

            context('With valid arguments.', function () {

                beforeEach('Book a product and store logs.', async function () {
                    this.expectedId = new web3.utils.BN(1);
                    this.expectedBooker = customer1;
                    ({ logs: this.logs } = await 
                        this.kibiwooInstance.book(
                            this.expectedId, 
                            this.start1, 
                            this.stop1, 
                            {from: this.expectedBooker}
                        )
                    );
                });

                it('Reverts if trying to book an already booked product', async function () {

                    await expectRevert(
                        this.kibiwooInstance.book(
                            this.expectedId, 
                            this.start1,
                            this.stop1,
                            {from: shop1}
                        ),
                        "BookingContract: Time blocks are unavailable."
                    );
                });

                it("Allows booking of similar timeslots but different product", async function() {
                    
                    let result = await this.kibiwooInstance.book(2, this.start1, this.stop1, {from: shop1});
                });
            });
        });
    });

    describe('#Test CancellBooking function', function() {

        it("Reverts if trying to cancel from a non-existent product.", async function() {
            await expectRevert(
                this.kibiwooInstance.cancel(10, 1000),
                'ERC721: cancel booking query for nonexistent token.'
            );
        });

        context('With correct values', function () {

            beforeEach('Create initial bookings', async function() {

                // TODO: generalize this function to store logs so that id of products is extracted from there.
                await this.kibiwooInstance.createNewProduct('Producto1', 0, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto2', 1, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto3', 2, {from: shop1});
                await this.kibiwooInstance.createNewProduct('Producto4', 0, {from: shop2});
                await this.kibiwooInstance.createNewProduct('Producto5', 0, {from: shop2});

                this.start1 = 1000+5*24*3600;
                this.stop1 = 1000+20*24*3600;
                this.start2 = 1000+30*24*3600;
                this.stop2 = 1000+35*24*3600;
                ({ logs: this.logs } = await 
                    this.kibiwooInstance.book(
                        0, 
                        this.start1, 
                        this.stop1, 
                        {from: customer1}
                    )
                );
                await this.kibiwooInstance.book(1, this.start2, this.stop2, {from: customer2});
            });

            it("Reverts if trying to cancel when not owning that booking.", async function() {
                await expectRevert(
                    this.kibiwooInstance.cancel(0, this.start1, {from: customer2}),
                    "ERC721: burn of token that is not own"
                );
            });

            it("Makes cancelled time period available again. Check events values.", async function () {
                await expectRevert(
                    this.kibiwooInstance.book(
                        0, 
                        this.start1, 
                        this.stop1, 
                        {from: customer2}
                    ), 
                    'BookingContract: Time blocks are unavailable.'
                );

                await this.kibiwooInstance.cancel(0, this.start1, {from: customer1});

                ({ logs: logs } = await 
                    this.kibiwooInstance.book(
                        0, 
                        this.start1, 
                        this.stop1, 
                        {from: customer2}
                    )
                );
            });
        });
    });
});