// import * as axios from 'axios';
// import Pino from 'pino';
// import config from '../config';

// import crypto from 'crypto';
// function uuidv4() {
//     return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
//         (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
//     );
// }
// const sessionId = uuidv4();

const logger = console;
// const logger = Pino({
//     browser: {
//         asObject: false,
//         transmit: {
//             // level: 'info',
//             send: async function (level, logEvent) {
//                 if (config.apiUrl) {
//                     const logSecret = location.hash;
//                     if (logSecret && logSecret !== '') {
//                         try {
//                             await axios.post(config.apiUrl + '/log/' + logSecret.substr(1) + '/' + sessionId, logEvent);
//                         } catch (e) {
//                             console.log('failed to log', e);
//                         }
//                     }
//                 }
//             }
//         }
//     }
// });

function traceCaller(n) {
    if (isNaN(n) || n < 0) {
        n = 1;
    }
    n += 1;
    let s = (new Error()).stack;
    let a = s.indexOf('\n', 5);
    while (n--) {
        a = s.indexOf('\n', a + 1);
        if (a < 0) {
            a = s.lastIndexOf('\n', s.length);
            break;
        }
    }

    let b = s.indexOf('\n', a + 1);
    if (b < 0) {
        b = s.length;
    }
    a = Math.max(s.lastIndexOf(' ', b), s.lastIndexOf('/', b));
    b = s.lastIndexOf(':', b);
    s = s.substring(a + 1, b);
    return s;
}

let logLevel = (typeof window != 'undefined' && typeof window.params != 'undefined') ? window.params.logLevel : undefined;
if (!logLevel) {
    if (typeof window != 'undefined' && typeof window._debug != 'undefined' && window._debug) {
        logLevel = 100;
    } else {
        logLevel = 20;
    }
}

export default {
    silent(...args) {
        if (process.browser) {
            if(logLevel >= 70) logger.silent(...args);
        }
    },
    trace(...args) {
        if (process.browser) {
            if(logLevel >= 60) logger.info(...args); //logger.trace(...args); // todo configure levels
        }
    },
    debug(...args) {
        if (process.browser) {
            if(logLevel >= 50 ) logger.info(...args);
        }
    },
    info(...args) {
        if (process.browser) {
            if(logLevel >= 40) logger.info(...args);
        }
    },
    warn(...args) {
        if (process.browser) {
            if(logLevel >= 30) logger.error(...args);
        }
    },
    error(...args) {
        if (process.browser) {
            if(logLevel >= 20) logger.error(...args);
        }
    },
    fatal(...args) {
        if (process.browser) {
            if(logLevel >= 10) logger.fatal(...args);
        }
    },
};
