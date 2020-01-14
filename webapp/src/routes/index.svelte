<script>
import wallet from '../stores/wallet';
import metatx from '../stores/metatx';
import relayer from '../stores/relayer';
import WalletWrapper from '../components/WalletWrapper';
import account from '../stores/account';
import * as ethers from 'ethers';
import {pause} from '../utils/time'

const { Wallet, Contract, BigNumber, AbiCoder } = ethers;

let purchase_amount = 1;
let purchase_expiry = 1610600198;
let purchase_txGas = 1000000;
let purchase_batchId = 0;
let purchase_nonce = undefined;
let purchase_tokenGasPrice = 0;
let purchase_relayer = "0x0000000000000000000000000000000000000000";

let transfer_amount = 0;
let transfer_expiry = 1610600198;
let transfer_txGas = 1000000;
let transfer_batchId = 0;
let transfer_nonce = undefined;
let transfer_tokenGasPrice = 0;
let transfer_relayer = "0x0000000000000000000000000000000000000000";


let transferTo;


async function relay() {

}
function errorToAscii(str1) {
	const l = 64 + 64 + 10;
	if (str1.length <= l) {
		return "UNKNOWN ERROR";
	}
	str1 = str1.slice(l);
	let str = '';
	for (let n = 0; n < str1.length; n += 2) {
		str += String.fromCharCode(parseInt(str1.substr(n, 2), 16));
	}
	return str;
}
async function getEventsFromReceipt(ethersProvider, ethersContract, sig, receipt) {
    let topic = ethers.utils.id(sig);
    let filter = {
        address: ethersContract.address,
        fromBlock: receipt.blockNumber,
        toBlock: receipt.blockNumber,
        topics: [ topic ]
    }

    const logs = await ethersProvider.getLogs(filter);
    return logs.map(l => ethersContract.interface.parseLog(l));
}

async function transferFirstNumber() {
	const nftAddress = wallet.getContract('Numbers').address;
	const daiAddress = wallet.getContract('DAI').address;
	const metaTxProcessorContract = wallet.getContract('GenericMetaTxProcessor');
	const metaTxProcessorAddress = metaTxProcessorContract.address;

	if (!ethers.utils.isAddress(transferTo)) {
		$metatx = {status: 'error', message: 'Please specify a valid address'};
		return false;
	} 

	const txData = await wallet.computeData('Numbers', 'transferFrom', $wallet.address, transferTo, $account.numbers[0]);
	const nonce = transfer_nonce ? BigNumber.from(transfer_nonce) :await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, transfer_batchId);

	const message = {
      from: $wallet.address,
	  to: nftAddress,
	  tokenContract: daiAddress,
	  amount: BigNumber.from(transfer_amount).mul('1000000000000000000').toString(),
	  data: txData.data,
	  batchNonce: BigNumber.from(transfer_batchId).mul(BigNumber.from(2).mul(128)).add(nonce.add(1)).toHexString(),
	  expiry: transfer_expiry,
	  txGas: transfer_txGas,
	  baseGas: 100000,
	  tokenGasPrice: transfer_tokenGasPrice,
	  relayer: transfer_relayer,
	}

	const msgParams = JSON.stringify({types:{
      EIP712Domain:[
        {name:"name",type:"string"},
        {name:"version",type:"string"},
        {name:"verifyingContract",type:"address"}
      ],
      ERC20MetaTransaction:[
		{name:"from",type:"address"},
		{name:"to",type:"address"},
		{name:"tokenContract",type:"address"},
		{name:"amount",type:"uint256"},
		{name:"data",type:"bytes"},
		{name:"batchNonce",type:"uint256"},
		{name:"expiry",type:"uint256"},
		{name:"txGas",type:"uint256"},
		{name:"baseGas",type:"uint256"},
		{name:"tokenGasPrice",type:"uint256"},
        {name:"relayer",type:"address"}
      ],
    },
    primaryType:"ERC20MetaTransaction",
    domain:{name:"Generic Meta Transaction",version:"1",verifyingContract: metaTxProcessorAddress},
	message
	});
	
	let response;
	try {
		response = await wallet.sign(msgParams);
	} catch(e) {
		$metatx = {status: 'error', message: 'signature rejected'};
		return false;
	}
	if (!response) {
		$metatx = {status: 'error', message: 'signature rejected, no response'};
		return false;
	}
	$metatx = {status: 'submitting'};
	await pause(0.4);

	const provider = wallet.getFallbackProvider();
	const relayerWallet = new Wallet($relayer.privateKey).connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayerWallet);
	
	$metatx = {status: 'waitingRelayer'};
	while($relayer.status != 'Loaded' && $relayer.status != 'Error') {
		await pause(1);
	}
	if ($relayer.status == 'Error') {
		$metatx = {status: 'error', message: $relayer.message};
		return false;
	}
	// await pause(0.4);

	if (message.relayer.toLowerCase() != '0x0000000000000000000000000000000000000000' && message.relayer.toLowerCase() != $relayer.address.toLowerCase()) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the message is destined to another relayer'};
		return false;
	} 

	if(message.expiry <  Date.now() /1000 ) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the expiry time is in the past'};
		return false;
	}else if(message.expiry <  Date.now() / 1000 - 60) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the expiry time is too short'};
		return false;
	}

	const actualMetaNonce = await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, transfer_batchId);
	const expectedBatchNonce = BigNumber.from(transfer_batchId).mul(BigNumber.from(2).mul(128)).add(actualMetaNonce.add(1)).toHexString();
	if (expectedBatchNonce != message.batchNonce) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the message has the wrong nonce'};
		return false;
	}
	console.log(expectedBatchNonce, message.batchNonce);

	let tx 
	try {
		tx = await metaTxProcessor.executeERC20MetaTx(
			[
				message.from,
				message.to,
				message.tokenContract,
				message.relayer,
			],
			message.amount,
			message.data,
			[
				message.batchNonce,
				message.expiry,
				message.txGas,
				message.baseGas,
				message.tokenGasPrice
			],
			response,
			relayerWallet.address,
			0,
			{gasLimit: BigNumber.from('2000000'), chainId: 1} // chainId = 1 is required for ganache
		);
	} catch(e) {
		// TODO error
		$metatx = {status: 'error', message: 'relayer tx failed'}; // TODO no balance ?
		return false;
	}

	$metatx = {status: 'txBroadcasted'};
	await pause(0.4);
	const receipt = await tx.wait();
	const events = await getEventsFromReceipt(provider, metaTxProcessor,"MetaTx(address,uint256,bool,bytes)" , receipt);
	// console.log(ethers.utils.defaultAbiCoder.decode(['Error(srtring)'],events[0].values[3]));
	// console.log(ethers.utils.toUtf8String(events[0].values[3]));
	if(!events[0].values[2]) {
		console.log(errorToAscii(events[0].values[3]));
	}
	console.log(receipt);
	$metatx = {status: 'none'};
	return receipt;
}

async function purchaseNumber() {
	const saleAddress = wallet.getContract('NumberSale').address;
	const daiAddress = wallet.getContract('DAI').address;
	const metaTxProcessorContract = wallet.getContract('GenericMetaTxProcessor');
	const metaTxProcessorAddress = metaTxProcessorContract.address;
	const txData = await wallet.computeData('NumberSale', 'purchase', $wallet.address, $wallet.address);
	const nonce = purchase_nonce ? BigNumber.from(purchase_nonce) :await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, purchase_batchId);

	const message = {
      from: $wallet.address,
	  to: saleAddress,
	  tokenContract: daiAddress,
	  amount: BigNumber.from(purchase_amount).mul('1000000000000000000').toString(),
	  data: txData.data,
	  batchNonce: BigNumber.from(purchase_batchId).mul(BigNumber.from(2).mul(128)).add(nonce.add(1)).toHexString(),
	  expiry: purchase_expiry,
	  txGas: purchase_txGas,
	  baseGas: 100000,
	  tokenGasPrice: purchase_tokenGasPrice,
	  relayer: purchase_relayer,
	}
	const msgParams = JSON.stringify({types:{
      EIP712Domain:[
        {name:"name",type:"string"},
        {name:"version",type:"string"},
        {name:"verifyingContract",type:"address"}
      ],
      ERC20MetaTransaction:[
		{name:"from",type:"address"},
		{name:"to",type:"address"},
		{name:"tokenContract",type:"address"},
		{name:"amount",type:"uint256"},
		{name:"data",type:"bytes"},
		{name:"batchNonce",type:"uint256"},
		{name:"expiry",type:"uint256"},
		{name:"txGas",type:"uint256"},
		{name:"baseGas",type:"uint256"},
		{name:"tokenGasPrice",type:"uint256"},
        {name:"relayer",type:"address"}
      ],
    },
    primaryType:"ERC20MetaTransaction",
    domain:{name:"Generic Meta Transaction",version:"1",verifyingContract: metaTxProcessorAddress},
	message
	});
	
	let response;
	try {
		response = await wallet.sign(msgParams);
	} catch(e) {
		$metatx = {status: 'error', message: 'signature rejected'};
		return false;
	}
	if (!response) {
		$metatx = {status: 'error', message: 'signature rejected, no response'};
		return false;
	}
	
	$metatx = {status: 'submitting'};
	await pause(0.4);
	const provider = wallet.getFallbackProvider();
	const relayerWallet = new Wallet($relayer.privateKey).connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayerWallet);

	$metatx = {status: 'waitingRelayer'};
	while($relayer.status != 'Loaded' && $relayer.status != 'Error') {
		await pause(1);
	}
	if ($relayer.status == 'Error') {
		$metatx = {status: 'error', message: $relayer.message};
		return false;
	}
	// await pause(0.4);
	let tx 
	try {
		tx = await metaTxProcessor.executeERC20MetaTx(
			[
				message.from,
				message.to,
				message.tokenContract,
				message.relayer,
			],
			message.amount,
			message.data,
			[
				message.batchNonce,
				message.expiry,
				message.txGas,
				message.baseGas,
				message.tokenGasPrice
			],
			response,
			relayerWallet.address,
			0,
			{gasLimit: BigNumber.from('2000000'), chainId: 1} // chainId = 1 is required for ganache
		);
	} catch(e) {
		// TODO error
		$metatx = {status: 'error', message: 'relayer tx failed'}; // TODO no balance ?
		return false;
	}
	
	$metatx = {status: 'txBroadcasted'};
	await pause(0.4);
	const receipt = await tx.wait();
	const events = await getEventsFromReceipt(provider, metaTxProcessor,"MetaTx(address,uint256,bool,bytes)" , receipt);
	if(!events[0].values[2]) {
		const errorString = errorToAscii(events[0].values[3]);
		$metatx = {status: 'error', message: 'MetaTx Mined but Error: ' + errorString};
		return false;
	}
	console.log(receipt);
	$metatx = {status: 'none'};
	return receipt;
}

async function permitDAI() {
	const dai = wallet.getContract('DAI');
	const metaTxProcessorAddress = wallet.getContract('GenericMetaTxProcessor').address;
	const msgParams = JSON.stringify({types:{
      EIP712Domain:[
        {name:"name",type:"string"},
		{name:"version",type:"string"},
		// {name:"chainId",type:"uint256"},
        {name:"verifyingContract",type:"address"}
      ],
      Permit:[
		{name:"holder",type:"address"},
		{name:"spender",type:"address"},
		{name:"nonce",type:"uint256"},
		{name:"expiry",type:"uint256"},
		{name:"allowed",type:"bool"}
      ],
    },
    primaryType:"Permit",
    domain:{name:"Dai Stablecoin",version:"1",verifyingContract: dai.address},
    message:{
      holder: $wallet.address,
	  spender: metaTxProcessorAddress,
	  nonce: 0, // TODO
	  expiry: 0,
	  allowed: true
	}});
	
	let response;
	try {
		response = await wallet.sign(msgParams);
	} catch(e) {
		$metatx = {status: 'error', message: 'signature rejected'};
		return false;
	}
	if (!response) {
		$metatx = {status: 'error', message: 'signature rejected, no response'};
		return false;
	}
	$metatx = {status: 'submitting'};
	await pause(0.4);

	const splitSig = ethers.utils.splitSignature(response);

	const provider = wallet.getFallbackProvider();
	const relayerWallet = new Wallet($relayer.privateKey).connect(provider);
	const DAI = new Contract(dai.address, dai.abi, relayerWallet);

	$metatx = {status: 'waitingRelayer'};
	while($relayer.status != 'Loaded' && $relayer.status != 'Error') {
		await pause(1);
	}
	if ($relayer.status == 'Error') {
		$metatx = {status: 'error', message: $relayer.message};
		return false;
	}
	// await pause(0.4);

	const tx = await DAI.permit(
		$wallet.address,
		metaTxProcessorAddress,
		0,
		0,
		true,
		splitSig.v,
		splitSig.r,
		splitSig.s,
		{gasLimit: BigNumber.from('1000000'), chainId: 1} // chainId = 1 is required for ganache
	);

	$metatx = {status: 'txBroadcasted'};
	await pause(0.4);
	const receipt = await tx.wait();
	console.log(receipt);
	$metatx = {status: 'none'};
	return receipt;
}
</script>

<style>
	h1, figure, p {
		text-align: center;
		margin: 0 auto;
	}

	h1 {
		font-size: 2.8em;
		text-transform: uppercase;
		font-weight: 700;
		margin: 0 0 0.5em 0;
	}

	figure {
		margin: 0 0 1em 0;
	}

	img {
		width: 100%;
		max-width: 400px;
		margin: 0 0 1em 0;
	}

	p {
		margin: 1em auto;
	}

	.center {
		text-align:center;
	}

	@media (min-width: 480px) {
		h1 {
			font-size: 4em;
		}
	}
</style>

<svelte:head>
	<title>Meta Tx Demo</title>
</svelte:head>

<WalletWrapper>
    <h2 class="center">Meta Tx Demo</h2>
    <!-- <figure>
        <img alt='Borat' src='great-success.png'>
        <figcaption>HIGH FIVE!</figcaption>
    </figure> -->

	
	
	{#if $account.status == 'Loading'}
	<hr/>
    <span> fetching account info </span>
	<hr/>
	{:else if $account.status == 'Loaded'}
		<hr/>
		<p>Your DAI Balance:</p>
		<hr/>
		<h3 class="center">{$account.daiBalance.div('1000000000000000000')}</h3>
		<hr/>
		{#if $account.hasApprovedMetaTxProcessorForDAI}
		<p><button on:click="{() => purchaseNumber()}">buy a Number for 1 DAI</button></p>
		<details>
			<summary>advanced Meta Tx settings</summary>
			<label>DAI amount</label><input type="number" bind:value={purchase_amount}/><br/>
			<label>expiry</label><input type="datetime" bind:value={purchase_expiry}/><br/>
			<label>txGas</label><input type="number" bind:value={purchase_txGas}/><br/>
			<label>batchId</label><input type="number" bind:value={purchase_batchId}/><br/>
			<label>nonce</label><input type="number" bind:value={purchase_nonce}/><br/>
			<label>tokenGasPrice</label><input type="number" bind:value={purchase_tokenGasPrice}/><br/>
			<label>relayer</label><input type="string" bind:value={purchase_relayer}/><br/>
		</details>
		{:else}
		<p>In order to purchase the Numbers NFT you first need to approve the MetaTx Processor to transfer DAI on your behalf.</p>
		<p><button on:click="{() => permitDAI()}">Approve MetaTx Processor</button></p>
		{/if}
		<br/>
		<br/>
		<hr/>
		<p>Your Numbers NFT below (only show 11 max) :</p>
		<hr/>
		<ul>
		{#each $account.numbers as item}
			<li>{item}</li>
		{:else}
		<p>You do not own any Number NFT yet!</p>
		{/each}
		</ul>
		{#if $account.numbers.length}
		<hr/>
		<p>Transfer Number ({$account.numbers[0]}) to another account</p>
		<p><input placeholder="address" bind:value={transferTo}/></p>
		<p><button on:click="{() => transferFirstNumber()}">transfer</button></p>
		<details>
			<summary>advanced Meta Tx settings</summary>
			<label>DAI amount</label><input type="number" bind:value={transfer_amount}/><br/>
			<label>expiry</label><input type="datetime" bind:value={transfer_expiry}/><br/>
			<label>txGas</label><input type="number" bind:value={transfer_txGas}/><br/>
			<label>batchId</label><input type="number" bind:value={transfer_batchId}/><br/>
			<label>nonce</label><input type="number" bind:value={transfer_nonce}/><br/>
			<label>tokenGasPrice</label><input type="number" bind:value={transfer_tokenGasPrice}/><br/>
			<label>relayer</label><input type="string" bind:value={transfer_relayer}/><br/>
		</details>
		{/if}
	{:else if $account.status == 'Unavailable'}
	<span> please unlock account </span>
	{:else}
	<span> ERROR </span>
	{/if}
	
</WalletWrapper>


