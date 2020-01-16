import log from '../utils/log';
import wallet from './wallet';
import { derived } from 'svelte/store';
// import { BigNumber } from 'ethers';

const $data = {
    status: 'Loading',
    daiBalance: undefined
};

let interval;
let account;
account = derived(wallet, ($wallet, set) => {
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
        }
    }

    async function fetch() {
        const metaTxProcessor = wallet.getContract('GenericMetaTxProcessor');
        const balance = await wallet.call('DAI', 'balanceOf', $wallet.address);
        const allowance = await wallet.call('DAI', 'allowance', $wallet.address, metaTxProcessor.address);
        const hasApprovedMetaTxProcessorForDAI = allowance.gt('10000000000000000000');

        // const numbers = wallet.getContract('Numbers');
        const nftBalance = await wallet.call('Numbers', 'balanceOf', $wallet.address);
        const items = [];
        for (let i = 0; i < Math.min(11, nftBalance); i++) {
            const id = await wallet.call('Numbers', 'tokenOfOwnerByIndex', $wallet.address, i);
            items.push(id);
        }

        const mtxBalance = await wallet.call('MTX', 'balanceOf', $wallet.address);

        const blockNumber = await wallet.getProvider().getBlockNumber();

        // const balance = await wallet.call('DAI', 'balanceOf', $wallet.address);
        _set({
            status: 'Loaded',
            daiBalance: balance,
            mtxBalance,
            hasApprovedMetaTxProcessorForDAI,
            numbers: items,
            blockNumber
            // TODO block,
        });
    }

    async function startListening(setLoading) {
        if (!interval) {
            if (setLoading) {
                _set({
                    status: 'Loading', // TODO only if no data already available ?
                    daiBalance: undefined
                });
            }
            fetch();
            interval = setInterval(() => {
                fetch();
            }, 5000); // TODO config interval
            console.log('start listenning', interval);
        }
    }

    async function stopListening() {
        // console.log('stop listenning', interval);
        if (interval) {
            // console.log('stop listenning');
            clearInterval(interval);
        }
        interval = undefined;
    }

    account.refresh = function() {
        stopListening();
        startListening(false);
    }

    if ($wallet.status === 'Ready' && !$wallet.chainNotSupported) {
        startListening();
    } else {
        // console.log('not ready now');
        stopListening(); // TODO Should we stop listening ?
        _set({ status: 'Unavailable', daiBalance: undefined });
    }
}, $data);

export default account;