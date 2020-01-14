import log from '../utils/log';
import WalletStore from 'svelte-wallet';

const wallet = WalletStore(log);
if (typeof window !== 'undefined') {
    window.wallet = wallet;
}

export const contractData = {};

import('contractsInfo').then((contractsInfo) => {
    const supportedChainIds = [];
    for(let chainId of Object.keys(contractsInfo)) {
        if (chainId != 'default') {
            supportedChainIds.push(chainId);
        }
    }
    
    let fallbackUrl;
    // if ( 
    //     (process.browser && location.host.startsWith('localhost')) ||
    //     (process.browser && location.host.startsWith('127.0.0.1'))
    // ) {
    //     fallbackUrl = 'http://localhost:8545';
    // } else if (contractsInfo['1']) {
    //     fallbackUrl = 'https://mainnet.infura.io/v3/';
    // } else if (contractsInfo['4']) {
    //     fallbackUrl = 'https://rinkeby.infura.io/v3/';
    // } else {
    //     fallbackUrl = 'http://localhost:8545';
    // }

    // if (process.browser) {
    //     fallbackUrl = (window.params && window.params.fallbackUrl) ? window.params.fallbackUrl : fallbackUrl;
    // }

    const walletTypes = ['builtin'];
    
    wallet.load({
        fallbackUrl,
        walletTypes, // TODO require user interaction to create a local Key (when claimKey available)
        supportedChainIds,
        reuseLastWallet: true,
        // fetchInitialBalance: true,
        registerContracts: async ($wallet, chainId) => {
            chainId = chainId || $wallet.chainId;
            if (contractsInfo[chainId]) {
                contractData.contractsInfo = contractsInfo[chainId];
                return contractsInfo[chainId];
            }
            throw new Error('no contract for chainId ' + chainId);
        }
    });
});

export default wallet; 
