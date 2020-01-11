
module.exports = {
    accounts: {
        "default":{
            type: "mnemonic",
            num: 10,
        }
    },
    useNetVersionAsChainId: true,
    blockTime: 6,
    namedAccounts: {
        deployer: 0,
        users: "from:2"
    },
}