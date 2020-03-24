const fs = require('fs');
usePlugin("buidler-deploy");

module.exports = {
  namedAccounts: {
      // TODO per chain
    deployer: 0,
    relayer: '0x7B7cd3876EC83efa98CbB251C3C0526eb355EA55',
    // users: "from:2"
  },
  solc: {
      version: '0.6.1',
      optimizer: {
          enabled: true,
          runs: 200
      }
  },
  paths: {
    sources: 'src'
  },
  networks: {
    // TODO blockTime: 6, ?
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/bc0bdd4eaac640278cdebc3aa91fabe4',
      accounts: {
        mnemonic: fs.readFileSync('.mnemonic').toString()
      }
    }
  }
};
