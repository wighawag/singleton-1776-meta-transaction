import log from '../utils/log';
import { writable } from 'svelte/store';

const $data = {
    status: 'none',
};

export default writable($data);

