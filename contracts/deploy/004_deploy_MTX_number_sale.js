
module.exports = async ({namedAccounts, deployments}) => {
    const {deployIfDifferent, log} = deployments;
    const {deployer} = namedAccounts;

    let processor = deployments.get('GenericMetaTxProcessor');
    let numbers = deployments.get('Numbers');
    let mtx = deployments.get('MTX');
    let contract = deployments.get('MTXNumberSale');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "MTXNumberSale",  {from: deployer, gas: 4000000}, "NumberSale", numbers.address, mtx.address, '1000000000000000000', processor.address);
        contract = deployments.get('MTXNumberSale');
        if(deployResult.newlyDeployed) {
            log(`MTXNumberSale deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}
// module.exports.skip = async () => true;