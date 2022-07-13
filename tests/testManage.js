const { expect } = require("chai");
const { time, loadFixture, impersonateAccount, setBalance } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy, setup, setupWithWhitelist, withProductLocalNative, withBatchProducts } = require("./fixtures.js");
const { native, sandDomain, bearDomain, tennisDomain, newFee, productId, productPrice, productStock, productPriceToUpdate, productStockToUpdate, batchProductIdsToAddStock, batchProductIdsToRemoveStock, anotherProductId, shippingCost } = require("./constants.json");
const { getRandomAddress, checkIfItemInArray, createRandomBatchProducts, getBatchProductIds, getStocks, getSignedMessage } = require("./functions.js");

describe("Crosschain CryptoAvisos - Manage functions", function () {

    before(async function () {
        [deployer, alice, bob, allowedSigner, newAllowedSigner] = await ethers.getSigners();
    });

    describe("Setup", function () {

        it("Should change allowed signer...", async function () {
            const { brain } = await loadFixture(deploy);

            let oldAllowedSignerAddress = await brain.allowedSigner();
            let newAllowedSignerAddress = newAllowedSigner.address;

            await brain.changeAllowedSigner(newAllowedSignerAddress);
            let allowedSigner = await brain.allowedSigner();

            expect(allowedSigner).equal(newAllowedSignerAddress);
            expect(oldAllowedSignerAddress).not.equal(allowedSigner);
        });

        it("Should add/update arm...", async function () {
            const { brain, armTennisChain } = await loadFixture(deploy);

            // add arm
            let randomTennisArm = getRandomAddress();

            await expect(brain.addArm(0, randomTennisArm)).to.be.revertedWith("!domain");
            await expect(brain.addArm(tennisDomain, ethers.constants.AddressZero)).to.be.revertedWith("!contractAddress");

            await brain.addArm(tennisDomain, randomTennisArm);
            await expect(brain.addArm(tennisDomain, randomTennisArm)).to.be.revertedWith("alreadyExists");

            expect(await brain.armRegistry(tennisDomain)).equal(randomTennisArm);

            // update arm
            await expect(brain.updateArm(tennisDomain, ethers.constants.AddressZero)).to.be.revertedWith("!contractAddress");
            await expect(brain.updateArm(1, randomTennisArm)).to.be.revertedWith("!exists");

            await brain.updateArm(tennisDomain, armTennisChain.address);

            expect(await brain.armRegistry(tennisDomain)).equal(armTennisChain.address);
        });

        it("Should add/remove, bind/update settlement token...", async function () {
            const { brain, sandFirstToken, bearFirstToken } = await loadFixture(deploy);

            // add
            let randomSettlementToken = getRandomAddress();
            await brain.addSettlementToken(randomSettlementToken);
            await brain.addSettlementToken(sandFirstToken.address);
            expect(checkIfItemInArray(await brain.getSettlementTokens(), randomSettlementToken)).equal(true);
            await expect(brain.addSettlementToken(sandFirstToken.address)).to.be.revertedWith("exists");
            await expect(brain.addSettlementToken(ethers.constants.AddressZero)).to.be.revertedWith("!zeroAddress");

            // remove
            await brain.removeSettlementToken(randomSettlementToken);
            expect(checkIfItemInArray(await brain.getSettlementTokens(), randomSettlementToken)).equal(false);
            await expect(brain.removeSettlementToken(ethers.constants.AddressZero)).to.be.revertedWith("!zeroAddress");

            // bind
            let randomForeignSettlementToken = getRandomAddress();
            await brain.bindSettlementToken(bearDomain, sandFirstToken.address, randomForeignSettlementToken);
            expect(await brain.tokenAddresses(bearDomain, sandFirstToken.address)).equal(randomForeignSettlementToken);
            await expect(brain.bindSettlementToken(bearDomain, getRandomAddress(), randomForeignSettlementToken)).to.be.revertedWith("!valid");

            // update bind
            await brain.updateBindSettlementToken(bearDomain, sandFirstToken.address, bearFirstToken.address);
            expect(await brain.tokenAddresses(bearDomain, sandFirstToken.address)).equal(bearFirstToken.address);
            await expect(brain.updateBindSettlementToken(bearDomain, getRandomAddress(), randomForeignSettlementToken)).to.be.revertedWith("!valid");
        });

        it("Should change fee...", async function () {
            const { brain } = await loadFixture(deploy);

            await expect(brain.implementFee()).to.be.revertedWith("!prepared");

            //Prepare
            await brain.prepareFee(ethers.utils.parseUnits(String(newFee)));
            await expect(brain.implementFee()).to.be.revertedWith("!unlocked");

            //Time travel
            await time.increase(604800); //1 week

            //Implement
            await brain.implementFee();

            expect(Number(ethers.utils.formatUnits(await brain.fee()))).to.equal(newFee);
        });

    });

    describe("Single functions", function () {

        it("Should add/remove from whitelist...", async function () {
            const { brain } = await loadFixture(setup);

            let seller = alice.address;

            // add
            await brain.addWhitelistedSeller(seller);
            expect(await brain.sellerWhitelist(seller)).equal(true);

            // remove
            await brain.removeWhitelistedSeller(seller);
            expect(await brain.sellerWhitelist(seller)).equal(false);
        });

        it("Should submit product successfully...", async function () {
            const { brain, sandFirstToken } = await loadFixture(setupWithWhitelist);

            let seller = alice;

            // submit product
            await brain.connect(seller).submitProduct(productId, seller.address, ethers.utils.parseUnits(productPrice), sandFirstToken.address, productStock, sandDomain);

            let product = await brain.productMapping(productId);
            expect(String(product.price)).equal(ethers.utils.parseUnits(productPrice));
            expect(product.seller).equal(seller.address);
            expect(product.token).equal(sandFirstToken.address);
            expect(product.enabled).equal(true);
            expect(product.outputPaymentDomain).equal(sandDomain);
            expect(product.stock).equal(productStock);
            expect(checkIfItemInArray((await brain.getProductsIds()).map(Number), productId)).equal(true);

            await expect(brain.connect(seller).submitProduct(0, seller.address, ethers.utils.parseUnits(productPrice), sandFirstToken.address, productStock, sandDomain)).to.be.revertedWith("!productId");
            await expect(brain.connect(seller).submitProduct(productId, seller.address, 0, sandFirstToken.address, productStock, sandDomain)).to.be.revertedWith("!price");
            await expect(brain.connect(seller).submitProduct(productId, ethers.constants.AddressZero, ethers.utils.parseUnits(productPrice), sandFirstToken.address, productStock, sandDomain)).to.be.revertedWith("!seller");
            await expect(brain.connect(seller).submitProduct(productId, seller.address, ethers.utils.parseUnits(productPrice), sandFirstToken.address, 0, sandDomain)).to.be.revertedWith("!stock");
            await expect(brain.connect(seller).submitProduct(productId, seller.address, ethers.utils.parseUnits(productPrice), sandFirstToken.address, productStock, sandDomain)).to.be.revertedWith("alreadyExist");
            await expect(brain.connect(bob).submitProduct(2, seller.address, ethers.utils.parseUnits(productPrice), sandFirstToken.address, productStock, sandDomain)).to.be.revertedWith("!whitelisted");
            await expect(brain.connect(seller).submitProduct(2, seller.address, ethers.utils.parseUnits(productPrice), getRandomAddress(), productStock, sandDomain)).to.be.revertedWith("!settlementToken");

        });

        it("Should update product successfully...", async function () {
            const { brain } = await loadFixture(withProductLocalNative);

            let seller = getRandomAddress();

            // update product
            await brain.updateProduct(productId, seller, ethers.utils.parseUnits(productPriceToUpdate), native, productStockToUpdate, bearDomain);

            let product = await brain.productMapping(productId);
            expect(String(product.price)).equal(ethers.utils.parseUnits(productPriceToUpdate));
            expect(product.seller).equal(seller);
            expect(product.token).equal(native);
            expect(product.outputPaymentDomain).equal(bearDomain);
            expect(product.stock).equal(productStockToUpdate);

            await expect(brain.connect(deployer).updateProduct(productId, seller, 0, native, productStockToUpdate, bearDomain)).to.be.revertedWith("!price");
            await expect(brain.connect(deployer).updateProduct(productId, ethers.constants.AddressZero, ethers.utils.parseUnits(productPriceToUpdate), native, productStockToUpdate, bearDomain)).to.be.revertedWith("!seller");
            await expect(brain.connect(deployer).updateProduct(productId, seller, ethers.utils.parseUnits(productPriceToUpdate), getRandomAddress(), productStockToUpdate, bearDomain)).to.be.revertedWith("!settlementToken");
            await expect(brain.connect(alice).updateProduct(productId, seller, ethers.utils.parseUnits(productPriceToUpdate), native, productStockToUpdate, bearDomain)).to.be.revertedWith("!whitelisted");
        });

        it("Switch enable/disable should work...", async function () {
            const { brain } = await loadFixture(withProductLocalNative);

            // disable
            await brain.connect(alice).switchEnable(productId, false);
            expect((await brain.productMapping(productId)).enabled).equal(false);

            // enable
            await brain.connect(alice).switchEnable(productId, true);
            expect((await brain.productMapping(productId)).enabled).equal(true);

            let random = getRandomAddress();
            await setBalance(random, 100n ** 18n);
            let randomSigner = await ethers.getSigner(random);
            await impersonateAccount(random);
            await expect(brain.connect(randomSigner).switchEnable(productId, false)).to.be.revertedWith("!whitelisted");
        });

        it("Add/remove stock should work...", async function () {
            const { brain } = await loadFixture(withProductLocalNative);

            // add stock
            let toAdd = 8;
            let stockBeforeAdding = (await brain.productMapping(productId)).stock
            await brain.addStock(productId, toAdd);
            expect((await brain.productMapping(productId)).stock).equal(Number(stockBeforeAdding) + toAdd);

            // remove stock
            let toRemove = toAdd;
            let stockBeforeRemoving = (await brain.productMapping(productId)).stock
            await brain.removeStock(productId, toRemove);
            expect((await brain.productMapping(productId)).stock).equal(Number(stockBeforeRemoving) - toRemove);
        });

    });

    describe("Batch functions", function () {

        it("Should submit products in batch...", async function () {
            const { brain, sandFirstToken } = await loadFixture(setupWithWhitelist);

            let ids = getBatchProductIds();
            let batch = createRandomBatchProducts(alice.address, [sandFirstToken.address, native], [sandDomain, bearDomain]);

            // submit in batch
            await brain.batchSubmitProduct(ids, batch);

            for (let i = 0; i < ids.length; i++) {
                const id = ids[i];
                const prod = batch[i];

                let product = await brain.productMapping(id);

                expect(String(product.price)).equal(String(prod.price));
                expect(product.seller).equal(prod.seller);
                expect(product.token).equal(prod.token);
                expect(product.enabled).equal(prod.enabled);
                expect(product.outputPaymentDomain).equal(prod.outputPaymentDomain);
                expect(product.stock).equal(prod.stock);
                expect(checkIfItemInArray((await brain.getProductsIds()).map(Number), productId)).equal(true);
            }

            await expect(brain.connect(bob).batchSubmitProduct(ids, batch)).to.be.revertedWith("!whitelisted");
        });

        it("Should update products in batch...", async function () {
            const { brain, sandFirstToken } = await loadFixture(withBatchProducts);

            [, alice] = await ethers.getSigners();

            let ids = getBatchProductIds();
            let batch = createRandomBatchProducts(alice.address, [sandFirstToken.address, native], [sandDomain, bearDomain]);

            // update products
            await brain.batchUpdateProduct(ids, batch);

            for (let i = 0; i < ids.length; i++) {
                const id = ids[i];
                const prod = batch[i];

                let product = await brain.productMapping(id);

                expect(String(product.price)).equal(String(prod.price));
                expect(product.seller).equal(prod.seller);
                expect(product.token).equal(prod.token);
                expect(product.enabled).equal(prod.enabled);
                expect(product.outputPaymentDomain).equal(prod.outputPaymentDomain);
                expect(product.stock).equal(prod.stock);
            }

            let fakeIds = [anotherProductId];
            await expect(brain.connect(alice).batchSubmitProduct(fakeIds, batch)).to.be.revertedWith("!whitelisted");
        });

        it("Should enable/disable products in batch...", async function () {
            const { brain, sandFirstToken } = await loadFixture(withBatchProducts);

            [, alice] = await ethers.getSigners();

            let ids = getBatchProductIds();

            // enable
            await brain.batchSwitchEnable(ids, true);
            for (let i = 0; i < ids.length; i++) {
                const id = ids[i];
                let product = await brain.productMapping(id);
                expect(product.enabled).equal(true);
            }

            // disable
            await brain.batchSwitchEnable(ids, false);
            for (let i = 0; i < ids.length; i++) {
                const id = ids[i];
                let product = await brain.productMapping(id);
                expect(product.enabled).equal(false);
            }

            let fakeIds = [anotherProductId];
            await expect(brain.connect(alice).batchSwitchEnable(fakeIds, true)).to.be.revertedWith("!whitelisted");
        });

        it("Should add/remove stock in batch...", async function () {
            const { brain, sandFirstToken } = await loadFixture(withBatchProducts);

            [, alice] = await ethers.getSigners();

            let ids = getBatchProductIds();

            // add
            let stocksBeforeAdding = await getStocks(brain, ids);
            await brain.batchAddStock(ids, batchProductIdsToAddStock);
            let stocksAfterAdding = await getStocks(brain, ids);
            for (let i = 0; i < batchProductIdsToAddStock.length; i++) {
                const item = batchProductIdsToAddStock[i];
                expect(stocksBeforeAdding[i] + item).equal(stocksAfterAdding[i]);
            }

            // remove
            let stocksBeforeRemoving = await getStocks(brain, ids);
            await brain.batchRemoveStock(ids, batchProductIdsToRemoveStock);
            let stocksAfterRemoving = await getStocks(brain, ids);
            for (let i = 0; i < batchProductIdsToRemoveStock.length; i++) {
                const item = batchProductIdsToRemoveStock[i];
                expect(stocksBeforeRemoving[i] - item).equal(stocksAfterRemoving[i]);
            }

            let fakeIds = [anotherProductId];
            await expect(brain.connect(alice).batchAddStock(fakeIds, batchProductIdsToAddStock)).to.be.revertedWith("!whitelisted");
            await expect(brain.connect(alice).batchRemoveStock(fakeIds, batchProductIdsToRemoveStock)).to.be.revertedWith("!whitelisted");
        });

    });

});