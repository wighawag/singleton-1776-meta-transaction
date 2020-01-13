
module.exports = async ({namedAccounts, initialRun, deployIfDifferent, getDeployedContract}) => {
    function log(...args) {
        if(initialRun) {
            console.log(...args);
        }
    }
    const {deployer} = namedAccounts;
    
    let contract = getDeployedContract('DAI');
    if (!contract) {
        const deployResult = await deployIfDifferent(['data'], "DAI",  {from: deployer, gas: 4000000}, "PAW", '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');
        contract = getDeployedContract('DAI');
        if(deployResult.newlyDeployed) {
            log(`DAI deployed at ${contract.address} for ${deployResult.receipt.gasUsed}`);
        }
    }
}