const { ethers } = require("hardhat");
const factoryJson = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const routerJson = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");

async function mockConstructor(
    deployer,
    nativeTokenName,
    nativeTokenSymbol,
    firstTokenName,
    firstTokenSymbol,
    secondTokenName,
    secondTokenSymbol
) {
    this.Connext = await ethers.getContractFactory("ConnextMock");
    this.FalseExecutorConnextMock = await ethers.getContractFactory("FalseExecutorConnextMock");
    this.UniswapV2Factory = new ethers.ContractFactory(factoryJson.abi, factoryJson.bytecode, deployer);
    this.UniswapV2Router02 = new ethers.ContractFactory(routerJson.abi, routerJson.bytecode, deployer);
    this.ERC20 = await ethers.getContractFactory("ERC20Mock");

    // deploy handler
    this.connext = await this.Connext.deploy();
    await this.connext.deployed();

    // deploy false executor
    this.falseExecutorConnextMock = await this.FalseExecutorConnextMock.deploy();
    await this.falseExecutorConnextMock.deployed();

    // deploy amm factory
    this.factory = await this.UniswapV2Factory.deploy(deployer.address);
    await this.factory.deployed();

    // deploy wNATIVE
    this.wNATIVE = await this.ERC20.deploy(nativeTokenName, nativeTokenSymbol);
    await this.wNATIVE.deployed();

    // deploy amm router
    this.router = await this.UniswapV2Router02.deploy(this.factory.address, this.wNATIVE.address);
    await this.router.deployed();

    // deploy ERC20
    this.firstToken = await this.ERC20.deploy(firstTokenName, firstTokenSymbol);
    await this.firstToken.deployed();

    // deploy ERC20
    this.secondToken = await this.ERC20.deploy(secondTokenName, secondTokenSymbol);
    await this.secondToken.deployed();

    return {
        "handler": this.connext,
        "falseExecutor": this.falseExecutorConnextMock,
        "factory": this.factory,
        "wNATIVE": this.wNATIVE,
        "router": this.router,
        "firstToken": this.firstToken,
        "secondToken": this.secondToken
    }

}

async function getSignedMessage(brainContract, shippingCost, productId, buyerAddress, signer) {
    let nonce = await brainContract.nonce();
    let hashedMessage = ethers.utils.solidityKeccak256(
        ["uint256", "address", "uint256", "uint256", "uint256"],
        [productId, buyerAddress, shippingCost, 31337, Number(nonce)]
    );
    let hashedMessageArray = ethers.utils.arrayify(hashedMessage);
    let signedMessage = await signer.signMessage(hashedMessageArray);
    return signedMessage;
}

module.exports = { mockConstructor, getSignedMessage };