
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;

    let contract = getDeployedContract('GenericMetaTxProcessor');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "GenericMetaTxProcessor",  {from: deployer, gas: 4000000}, "GenericMetaTxProcessor");
        contract = getDeployedContract('GenericMetaTxProcessor');
        if(deployResult.newlyDeployed) {
            log(`GenericMetaTxProcessor deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}