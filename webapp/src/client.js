import * as sapper from '@sapper/app';

import './init';

sapper.start({
	target: document.querySelector('#sapper')
});