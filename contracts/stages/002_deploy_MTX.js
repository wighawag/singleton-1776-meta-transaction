
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    let processor = getDeployedContract('GenericMetaTxProcessor');
    let contract = getDeployedContract('MTX');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "MTX",  {from: deployer, gas: 4000000}, "PAW", '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', processor.address);
        contract = getDeployedContract('MTX');
        if(deployResult.newlyDeployed) {
            log(`MTX deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}
// module.exports.skip = async () => true;