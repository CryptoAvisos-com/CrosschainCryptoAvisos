const { expect } = require("chai");
const { time, loadFixture, impersonateAccount, setBalance } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy, setup, setupWithWhitelist, withProductLocalNative, withBatchProducts } = require("./fixtures.js");
const { native, sandDomain, bearDomain, tennisDomain, newFee, productId, productPrice, productStock, productPriceToUpdate, productStockToUpdate, batchProductIdsToAddStock, batchProductIdsToRemoveStock, anotherProductId, shippingCost } = require("./constants.json");
const { getRandomAddress, checkIfItemInArray, createRandomBatchProducts, getBatchProductIds, getStocks, getSignedMessage } = require("./functions.js");

describe("Crosschain CryptoAvisos - PayProduct functions", function () {

    before(async function () {
        [deployer, alice, bob, allowedSigner, newAllowedSigner] = await ethers.getSigners();
    });

    describe("Pay product (local)", function () {

        it("Should pay product locally (native)...", async function () {
            const { brain } = await loadFixture(withProductLocalNative);

            let price = ethers.utils.formatUnits((await brain.productMapping(productId)).price);
            let shipping = ethers.utils.parseUnits(String(shippingCost));
            let signedShippingCost = await getSignedMessage(brain, shipping, productId, bob.address, allowedSigner);

            let toSend = ethers.utils.parseUnits(String(Number(price) + shippingCost));

            await brain.connect(bob).payProduct(productId, shipping, signedShippingCost, { value: toSend });
        });

        it("Should pay product locally (token)...", async function () {

        });

        it("Should release payment locally (native)...", async function () {

        });

        it("Should release payment locally (token)...", async function () {

        });

        it("Should refund payment locally (native)...", async function () {

        });

        it("Should refund payment locally (token)...", async function () {

        });

        it("Should claim fees (native)...", async function () {

        });

        it("Should claim fees (token)...", async function () {

        });

        it("Should claim shipping cost (native)...", async function () {

        });

        it("Should claim shipping cost (token)...", async function () {

        });

    });

    describe("Pay product (crosschain)", function () {

        it("Should pay product crosschain (native)...", async function () {

        });

        it("Should pay product crosschain (token)...", async function () {

        });

        it("Should release payment crosschain (native)...", async function () {

        });

        it("Should release payment crosschain (token)...", async function () {

        });

        it("Should refund payment crosschain (native)...", async function () {

        });

        it("Should refund payment crosschain (token)...", async function () {

        });

    });

    describe("Pay product (crosschain with swap)", function () {

        it("Should pay product with swap (from eth to token)...", async function () {

        });

        it("Should pay product with swap (from token to token)...", async function () {

        });

        it("Should pay product with swap (from token to eth)...", async function () {

        });

    });

});