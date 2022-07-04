const { ethers } = require("hardhat");
const { setupDapps } = require("./functions");
const { productsForSingle, productsForBatch, initialFee, newFee, sandDomain } = require("./constants.json");

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
        "sandFirstToken":this.sandFirstToken,
        "tennisFirstToken": this.tennisFirstToken,
        "bearFirstToken": this.bearFirstToken
    }

}

module.exports = { deploy };