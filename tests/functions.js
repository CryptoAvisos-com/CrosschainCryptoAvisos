const { ethers, network } = require("hardhat");
const factoryJson = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const routerJson = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const { batchProductIds } = require("./constants.json");

async function setupDapps(
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

async function getSignedMessage(brain, shippingCost, productId, buyer, signer) {
    let nonce = await brain.nonce();
    let chainId = await brain.getChainId();

    let hashedMessage = ethers.utils.solidityKeccak256(
        ["uint256", "address", "uint256", "uint256", "uint256"],
        [productId, buyer, shippingCost, Number(chainId), Number(nonce)]
    );

    let hashedMessageArray = ethers.utils.arrayify(hashedMessage);
    let signedMessage = await signer.signMessage(hashedMessageArray);
    return signedMessage;
}

function getRandomAddress() {
    return ethers.Wallet.createRandom().address;
}

function checkIfItemInArray(array, item) {
    if (array.indexOf(item) == -1) {
        return false
    }
    return true
}

async function submitProduct(brain, productId, seller, productPrice, token, productStock, outputPaymentDomain) {
    // submit product
    await brain.connect(seller).submitProduct(productId, seller.address, ethers.utils.parseUnits(productPrice), token, productStock, outputPaymentDomain);
}

function getBatchProductIds() {
    return batchProductIds;
}

function getRandomItem(array) {
    return array[Math.floor(Math.random() * array.length)];
}

function getRandomNumber(min, max) {
    return parseInt(Math.random() * (max - min) + min);
}

function createRandomBatchProducts(sellerAddress, tokens, domains) {
    let batch = [];
    let ids = getBatchProductIds();

    for (let i = 0; i < ids.length; i++) {
        let price = ethers.utils.parseUnits(String(getRandomNumber(200, 500)));
        let seller = sellerAddress;
        let token = getRandomItem(tokens);
        let enabled = true;
        let outputPaymentDomain = getRandomItem(domains);
        let stock = getRandomNumber(1, 10);

        batch.push({
            price,
            seller,
            token,
            enabled,
            outputPaymentDomain,
            stock
        });
    }

    return batch;
}

async function getStocks(brain, ids) {
    let stocks = [];

    for (let i = 0; i < ids.length; i++) {
        const id = ids[i];

        let product = await brain.productMapping(id);
        stocks.push(Number(product.stock));
    }

    return stocks;
}

module.exports = { setupDapps, getSignedMessage, getRandomAddress, checkIfItemInArray, submitProduct, getBatchProductIds, createRandomBatchProducts, getStocks };