import log from '../utils/log';
import wallet from './wallet';
import { derived } from 'svelte/store';
// import { BigNumber } from 'ethers';

const $data = {
    status: 'Loading',
    daiBalance: undefined
};

let interval;
export default derived(wallet, ($wallet, set) => {
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
        // const balance = await wallet.call('DAI', 'balanceOf', $wallet.address);
        _set({
            status: 'Loaded',
            daiBalance: balance,
            hasApprovedMetaTxProcessorForDAI
            // TODO block,
        });
    }

    async function startListening() {
        if (!interval) {
            _set({
                status: 'Loading', // TODO only if no data already available ?
                daiBalance: undefined
            });
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

    if ($wallet.status === 'Ready') {
        startListening();
    } else {
        // console.log('not ready now');
        stopListening(); // TODO Should we stop listening ?
        _set({ status: 'Unavailable', daiBalance: undefined });
    }
}, $data);
