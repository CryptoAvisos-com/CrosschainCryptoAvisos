const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deploy } = require("./fixtures.js");
const { bearDomain, tennisDomain } = require("./constants.json");
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

        it("Should add/remove, bind/update settlement token", async function () {
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

    });

    describe("Single functions", function () {

    });

    describe("Batch functions", function () {

    });

    describe("Pay product (local)", function () {

    });

    describe("Pay product (crosschain)", function () {

    });

});