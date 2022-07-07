const { expect } = require("chai");
const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy, setup, setupWithWhitelist, withProductLocalNative } = require("./fixtures.js");
const { native, sandDomain, bearDomain, tennisDomain, newFee, productId, productPrice, productStock, productPriceToUpdate, productStockToUpdate } = require("./constants.json");
const { getRandomAddress, checkIfItemInArray } = require("./functions.js");

describe("Crosschain CryptoAvisos", function () {

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

        });

        it("Add/remove stock should work...", async function () {

        });

    });

    describe("Batch functions", function () {

    });

    describe("Pay product (local)", function () {

    });

    describe("Pay product (crosschain)", function () {

    });

});