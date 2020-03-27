import { store} from '@graphprotocol/graph-ts';
import { Transfer } from '../generated/Numbers/NumbersContract';
import { Numbers } from '../generated/schema';

// import { log } from '@graphprotocol/graph-ts';

let zeroAddress = '0x0000000000000000000000000000000000000000';

export function handleTransfer(event: Transfer): void {
    let id = event.params.tokenId.toString();
    let numbers = Numbers.load(id);
    if(numbers == null) {
        numbers = new Numbers(id);
        numbers.timestamp = event.block.timestamp;
    } else if(event.params.to.toHex() == zeroAddress) { //burnt
        store.remove('Numbers', id);
    }
    if(event.params.to.toHex() != zeroAddress) { // ignore transfer to zero
        numbers.owner = event.params.to;
        numbers.save();
    }
}
