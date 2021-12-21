let { networkConfig } = require("../helper-hardhat-config");


module.exports = async ({ deployments, getNamedAccounts, getChainId }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    const SupplyChain = await deploy("SupplyChain", {
        from: deployer,
        log: true,
    });

    const SupplyChainContract = await ethers.getContractFactory("SupplyChain");
    const accounts = await ethers.getSigners();
    const signer = accounts[0];



    const supplyChain = new ethers.Contract(
        SupplyChain.address,
        SupplyChainContract.interface,
        signer
    )

    const networkName = networkConfig[chainId]["name"];

    log(
        ` Verify with : \n  npx hardhat verify --network ${networkName}  ${SupplyChain.address}`
    );

    await supplyChain.createProduct(
        "Pipsi",
        "a cold drink",
        1000
    );

    const result = await supplyChain.fetchProduct(0);

    await supplyChain.shipProudct(
        0,
        1400
    );
    const result1 = await supplyChain.fetchProduct(0);

    log(` a product created:  ${result} ,,,,,,,, ${result1}`);

}