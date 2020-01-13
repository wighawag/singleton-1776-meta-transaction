
module.exports = async ({namedAccounts, sendTxAndWait}) => {
    const {deployer, relayer} = namedAccounts;
    await sendTxAndWait({from: deployer, to: relayer, value: '1000000000000000000'});
}