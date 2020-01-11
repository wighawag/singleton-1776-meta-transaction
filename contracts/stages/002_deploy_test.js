
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    
    let processor = getDeployedContract('GenericMetaTxProcessor');
    let contract = getDeployedContract('ExampleReceiver');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "ExampleReceiver",  {from: deployer, gas: 4000000}, "ExampleReceiver", processor.address);
        contract = getDeployedContract('ExampleReceiver');
        if(deployResult.newlyDeployed) {
            log(`ExampleReceiver deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}