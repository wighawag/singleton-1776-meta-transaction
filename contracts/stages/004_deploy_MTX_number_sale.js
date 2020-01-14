
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    
    let processor = getDeployedContract('GenericMetaTxProcessor');
    let numbers = getDeployedContract('Numbers');
    let mtx = getDeployedContract('MTX');
    let contract = getDeployedContract('MTXNumberSale');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "MTXNumberSale",  {from: deployer, gas: 4000000}, "NumberSale", numbers.address, mtx.address, '1000000000000000000', processor.address);
        contract = getDeployedContract('MTXNumberSale');
        if(deployResult.newlyDeployed) {
            log(`MTXNumberSale deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}
// module.exports.skip = async () => true;