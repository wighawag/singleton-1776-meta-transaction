
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    
    let processor = getDeployedContract('GenericMetaTxProcessor');
    let contract = getDeployedContract('Numbers');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "Numbers",  {from: deployer, gas: 4000000}, "Numbers", processor.address);
        contract = getDeployedContract('Numbers');
        if(deployResult.newlyDeployed) {
            log(`Numbers deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}
