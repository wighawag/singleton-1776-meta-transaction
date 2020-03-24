
module.exports = async ({namedAccounts, deployments}) => {
    const {sendTxAndWait} = deployments;
    const {deployer} = namedAccounts;

    await sendTxAndWait({from: deployer, to: relayer, value: '1000000000000000000'});
}
module.exports.skip = async () => true;