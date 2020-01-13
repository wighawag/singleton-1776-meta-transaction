
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
        relayer: '0x7B7cd3876EC83efa98CbB251C3C0526eb355EA55',
        users: "from:2"
    },
}