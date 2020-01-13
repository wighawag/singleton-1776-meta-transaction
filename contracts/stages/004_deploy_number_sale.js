
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    
    let processor = getDeployedContract('GenericMetaTxProcessor');
    let numbers = getDeployedContract('Numbers');
    let dai = getDeployedContract('DAI');
    let contract = getDeployedContract('NumberSale');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "NumberSale",  {from: deployer, gas: 4000000}, "NumberSale", numbers.address, dai.address, '1000000000000000000', processor.address);
        contract = getDeployedContract('NumberSale');
        if(deployResult.newlyDeployed) {
            log(`NumberSale deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}