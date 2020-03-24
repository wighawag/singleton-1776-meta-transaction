
module.exports = async ({namedAccounts, deployments}) => {
    const {deployIfDifferent, log} = deployments;
    const {deployer} = namedAccounts;

    let contract = deployments.get('GenericMetaTxProcessor');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "GenericMetaTxProcessor",  {from: deployer, gas: 4000000}, "GenericMetaTxProcessor");
        contract = deployments.get('GenericMetaTxProcessor');
        if(deployResult.newlyDeployed) {
            log(`GenericMetaTxProcessor deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}