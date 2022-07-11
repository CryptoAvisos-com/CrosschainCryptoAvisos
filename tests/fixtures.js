const { ethers } = require("hardhat");
const { setupDapps, submitProduct, getBatchProductIds, createRandomBatchProducts } = require("./functions");
const { productsForSingle, productsForBatch, initialFee, newFee, sandDomain, bearDomain, tennisDomain, native, productId, productStock, productPrice, anotherProductId } = require("./constants.json");

async function deploy() {

    [deployer] = await ethers.getSigners();
    this.Brain = await ethers.getContractFactory("Brain");
    this.Arm = await ethers.getContractFactory("Arm");

    /** SAND CHAIN (main chain) */

    this.sandChainMocks = await setupDapps(deployer, "Wrapped sand", "wSAND", "Sand castle", "CASTLE", "Beach voley", "VOLEY");
    this.sandConnextHandler = this.sandChainMocks.handler;
    this.sandFalseExecutor = this.sandChainMocks.falseExecutor;
    this.sandFactory = this.sandChainMocks.factory;
    this.sandWrapped = this.sandChainMocks.wNATIVE;
    this.sandRouter = this.sandChainMocks.router;
    this.sandFirstToken = this.sandChainMocks.firstToken;
    this.sandSecondToken = this.sandChainMocks.secondToken;

    // deploy brain
    this.brain = await this.Brain.deploy(ethers.utils.parseUnits(String(initialFee)), deployer.address, this.sandConnextHandler.address, this.sandRouter.address, this.sandWrapped.address);
    await this.brain.deployed();

    /** TENNIS CHAIN (arm chain 0) */

    this.tennisChainMocks = await setupDapps(deployer, "Wrapped tennis", "wTENNIS", "Tennis racket", "RACKET", "Tennis ball", "BALL");
    this.tennisConnextHandler = this.tennisChainMocks.handler;
    this.tennisFalseExecutor = this.tennisChainMocks.falseExecutor;
    this.tennisFactory = this.tennisChainMocks.factory;
    this.tennisWrapped = this.tennisChainMocks.wNATIVE;
    this.tennisRouter = this.tennisChainMocks.router;
    this.tennisFirstToken = this.tennisChainMocks.firstToken;
    this.tennisSecondToken = this.tennisChainMocks.secondToken;

    // deploy arm
    this.armTennisChain = await this.Arm.deploy(this.tennisRouter.address, this.tennisWrapped.address, this.tennisConnextHandler.address);
    await this.armTennisChain.deployed();

    /** BEAR CHAIN (arm chain 1) */

    this.bearChainMocks = await setupDapps(deployer, "Wrapped BEAR", "wBEAR", "Bear claw", "CLAW", "Bear ears", "EARS");
    this.bearConnextHandler = this.bearChainMocks.handler;
    this.bearFalseExecutor = this.bearChainMocks.falseExecutor;
    this.bearFactory = this.bearChainMocks.factory;
    this.bearWrapped = this.bearChainMocks.wNATIVE;
    this.bearRouter = this.bearChainMocks.router;
    this.bearFirstToken = this.bearChainMocks.firstToken;
    this.bearSecondToken = this.bearChainMocks.secondToken;

    // deploy arm
    this.armBearChain = await this.Arm.deploy(this.bearRouter.address, this.bearWrapped.address, this.bearConnextHandler.address);
    await this.armBearChain.deployed();

    return {
        "brain": this.brain,
        "armTennisChain": this.armTennisChain,
        "armBearChain": this.armBearChain,
        "sandFirstToken": this.sandFirstToken,
        "tennisFirstToken": this.tennisFirstToken,
        "bearFirstToken": this.bearFirstToken,
        "tennisSecondToken": this.tennisSecondToken
    }

}

async function setup() {

    const { brain, armTennisChain, armBearChain, sandFirstToken, tennisFirstToken, bearFirstToken, tennisSecondToken } = await deploy();

    // add arms
    await brain.addArm(tennisDomain, armTennisChain.address);
    await brain.addArm(bearDomain, armBearChain.address);

    // add settlement tokens
    await brain.addSettlementToken(sandFirstToken.address);
    await brain.addSettlementToken(native);

    // bind token
    await brain.bindSettlementToken(tennisDomain, sandFirstToken.address, tennisFirstToken.address);
    await brain.bindSettlementToken(bearDomain, sandFirstToken.address, bearFirstToken.address);
    await brain.bindSettlementToken(tennisDomain, native, tennisSecondToken.address);

    return {
        "brain": brain,
        "sandFirstToken": sandFirstToken
    }

}

async function setupWithWhitelist() {

    const { brain, sandFirstToken } = await setup();
    [, alice] = await ethers.getSigners();

    let seller = alice.address;

    // add
    await brain.addWhitelistedSeller(seller);

    return {
        "brain": brain,
        "sandFirstToken": sandFirstToken
    }

}

async function withBatchProducts() {

    const { brain, sandFirstToken } = await setup();
    [deployer, alice] = await ethers.getSigners();

    let ids = getBatchProductIds();
    let batch = createRandomBatchProducts(alice.address, [sandFirstToken.address, native], [sandDomain, bearDomain]);

    // submit in batch
    await brain.batchSubmitProduct(ids, batch);

    // another product
    await brain.submitProduct(anotherProductId, deployer.address, 200, native, 1, sandDomain);

    return {
        "brain": brain,
        "sandFirstToken": sandFirstToken
    }

}

async function withProductLocalNative() {

    const { brain } = await setupWithWhitelist();

    [, alice] = await ethers.getSigners();

    let seller = alice;
    let token = native;
    let outputPaymentDomain = sandDomain;

    await submitProduct(brain, productId, seller, productPrice, token, productStock, outputPaymentDomain);

    return {
        "brain": brain
    }

}

module.exports = { deploy, setup, setupWithWhitelist, withProductLocalNative, withBatchProducts };