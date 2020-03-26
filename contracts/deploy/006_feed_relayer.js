
module.exports = async ({namedAccounts, deployments}) => {
    const {sendTxAndWait, chainId} = deployments;
    const {deployer, relayer} = namedAccounts;

    if (chainId === '31337') {
        console.log('feeding relayer ' + relayer);
        await sendTxAndWait({from: deployer, to: relayer, value: '1000000000000000000'});
    }
}
// module.exports.skip = async () => true;