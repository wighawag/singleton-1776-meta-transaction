
module.exports = async ({namedAccounts, deployments}) => {
    const {deployIfDifferent, log} = deployments;
    const {deployer} = namedAccounts;

    let processor = deployments.get('GenericMetaTxProcessor');
    let contract = deployments.get('ExampleReceiver');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "ExampleReceiver",  {from: deployer, gas: 4000000}, "ExampleReceiver", processor.address);
        contract = deployments.get('ExampleReceiver');
        if(deployResult.newlyDeployed) {
            log(`ExampleReceiver deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}
module.exports.skip = async () => true;