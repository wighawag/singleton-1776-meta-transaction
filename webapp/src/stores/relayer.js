import log from '../utils/log';
import wallet from './wallet';
import { derived } from 'svelte/store';
import * as ethers from 'ethers';
import {pause} from '../utils/time'
const { Wallet, Contract, BigNumber, AbiCoder } = ethers;

const $data = {
    status: 'Loading'
};

let localStorageData = {};
if (process.browser) {
    try {
        const localStorageString = localStorage.getItem('_relayer');
        localStorageData = JSON.parse(localStorageString);
        delete localStorageData.status;
    } catch(e){}
    if (!localStorageData) {
        const relayer = Wallet.createRandom();
        localStorageData = {
            address: relayer.address,
            privateKey: relayer.privateKey
        }
        try {
            localStorage.setItem('_relayer', JSON.stringify(localStorageData));
        } catch(e) {}
        let testLocalStorage
        try {
            const localStorageString = localStorage.getItem('_relayer');
            testLocalStorage = JSON.parse(localStorageString);
        } catch(e){}
        if (!testLocalStorage) {
            $data = {
                status: 'Error',
                message: 'localStorage not working'
            };
        }
    }
}

let inProgress = false;
let provider;
const store = derived(wallet, async ($wallet, set) => {
    function _set(obj) {
        let diff = 0;
        for (let key of Object.keys(obj)) {
            if ($data[key] !== obj[key]) {
                $data[key] = obj[key];
                diff++;
            }
        }
        if (diff > 0) {
            log.info('ACCOUNT DATA', JSON.stringify($data, null, '  '));
            set($data);
            try{
                localStorage.setItem('_relayer', JSON.stringify($data));
            } catch(e){}
        }
    }

    if (localStorageData) {
        _set(localStorageData);
    }

    if (!$wallet.chainNotSupported && $wallet.builtinWalletPresent && $wallet.chainId && !inProgress) {
        inProgress = true;
        const chainId = $wallet.chainId;
        // console.log(chainId);
        let url;
        if (chainId == '1') {
            url = 'https://mainnet.infura.io/v3/';
        } else if(chainId == '4') {
            url = 'https://rinkeby.infura.io/v3/';
        } else if (chainId == '5') {
            url = 'https://goerli.infura.io/v3/';
        } else if (chainId == '42') {
            url = 'https://kovan.infura.io/v3/';
        } else {
            url = 'http://localhost:8545'; // TODO have more check if we support other
        }
        const txField = 'tx_on_chain_' + chainId;
        // const provider = wallet.getFallbackProvider();
        provider = new ethers.providers.JsonRpcProvider(url); // Why cannot we use the builtin provider (metamask?)
        if ($data[txField]) {
            const tx = await provider.getTransaction($data[txField]);
            if (tx.blockHash) {
                const currentBalance = await provider.getBalance($data.address);
                if (currentBalance.lt('1000000000000000')) {
                    _set({ status: 'Error', message: 'relayer balance too low, please send ETH to ' + $data.address});     
                } else {
                    _set({ status: 'Loaded' });
                }
            } else {
                let mined = false;
                while(!mined) {
                    await pause(2);
                    const tx = await provider.getTransaction($data.fundingTx);
                    // TODO Error
                    mined = !!tx.blockHash;
                }
                _set({ status: 'Loaded' });  
            }
            
        } else {
            const privateKey = '0xf912c020908da6935d420274cb1fa5fe609296ee3898bc190608a8d836463e27';
            const funderWallet = new Wallet(BigNumber.from(privateKey).sub(1).toHexString()); // just to prevent bot
            _set({funderAddress: funderWallet.address});
            const currentBalance = await provider.getBalance(funderWallet.address);
            if (currentBalance.lt(ethers.utils.parseEther('0.11'))) {
                _set({ status: 'Error', message: 'Oups, we do not have any more fund to topup any new relayer, please send ETH to ' + funderWallet.address + ' and reload'});     
            } else {
                const funder = funderWallet.connect(provider);
                let txData = {
                    to: $data.address,
                    value: ethers.utils.parseEther('0.1'),
                    chainId: 1 // TODO
                };
                // const tx = await funder.sendTransaction(txData);
                
                // let txObject = {};
                // txObject[txField] = tx.hash;
                // _set(txObject);
                // const receipt = await tx.wait();
                // console.log('FUNDING RECEIPT', receipt);
                // // TODO try catch no fund
                _set({ status: 'Loaded'});
            }
        }
    } else {
        // _set({ status: 'Unavailable' });
    }
}, $data);

store.getProvider = () => provider;

export default store;