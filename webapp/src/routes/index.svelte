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
	const mtxAddress = wallet.getContract('MTX').address;
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
	  tokenContract: mtxAddress,
	  amount: BigNumber.from(transfer_amount).mul('1000000000000000000').toString(),
	  data: txData.data,
	  batchId: transfer_batchId,
	  batchNonce: nonce.add(1).toHexString(),
	  expiry: transfer_expiry,
	  txGas: transfer_txGas,
	  baseGas: 100000,
	  tokenGasPrice: BigNumber.from(transfer_tokenGasPrice * 1000000000).mul('1000000000').toString(), // TODO use decimals
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
		{name:"batchId",type:"uint256"},
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

	const provider = relayer.getProvider();
	const relayerWallet = new Wallet($relayer.privateKey).connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayerWallet);
	
	const currentBalance = await provider.getBalance(relayerWallet.address);
	if (currentBalance.lt('1000000000000000')) {
		$metatx = {status: 'error', message: 'relayer balance too low, please send ETH to ' + relayerWallet.address};
		return false;     
	}

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
	const expectedBatchNonce = actualMetaNonce.add(1).toHexString();
	if (expectedBatchNonce != message.batchNonce) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the message has the wrong nonce'};
		return false;
	}
	console.log(expectedBatchNonce, message.batchNonce);

	let tx 
	try {
		tx = await metaTxProcessor.executeMetaTransaction(
			{
				from: message.from,
				to: message.to,
				data: message.data,
				signature: response,
				signatureType: 0
			},
			{
				tokenContract: message.tokenContract,
				amount: message.amount,
				batchId: message.batchId,
        		batchNonce: message.batchNonce,
        		expiry: message.expiry,
        		txGas: message.txGas,
        		baseGas: message.baseGas,
        		tokenGasPrice: message.tokenGasPrice,
        		relayer: message.relayer,
			},
			relayerWallet.address,
			{gasLimit: BigNumber.from('2000000'), chainId: relayer.getChainIdToUse()}
		);
	} catch(e) {
		// TODO error
		console.log(e);
		$metatx = {status: 'error', message: 'relayer tx failed at submission'};
		return false;
	}

	$metatx = {status: 'txBroadcasted'};
	await pause(0.4);
	let receipt;
	try {
		receipt = await tx.wait();
	} catch(e) {
		// TODO error
		console.log(e);
		$metatx = {status: 'error', message: 'relayer tx failed'};
		return false;
	}
	const metaTxEvent = receipt.events.find((event) => event.event === 'MetaTx' && event.address === metaTxProcessor.address);
	if (!metaTxEvent.args[2]){
		console.log(errorToAscii(metaTxEvent.args[3]));	
	}
	
	console.log(receipt);
	account.refresh();
	$metatx = {status: 'txConfirmed'};
	while($account.blockNumber < receipt.blockNumber) {
		await pause(0.5);
	}
	$metatx = {status: 'none'};
	return receipt;
}

async function purchaseNumber() {
	const saleAddress = wallet.getContract('MTXNumberSale').address;
	const mtxAddress = wallet.getContract('MTX').address;
	const metaTxProcessorContract = wallet.getContract('GenericMetaTxProcessor');
	const metaTxProcessorAddress = metaTxProcessorContract.address;
	const txData = await wallet.computeData('MTXNumberSale', 'purchase', $wallet.address, $wallet.address);
	const nonce = purchase_nonce ? BigNumber.from(purchase_nonce) :await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, purchase_batchId);

	const message = {
      from: $wallet.address,
	  to: saleAddress,
	  tokenContract: mtxAddress,
	  amount: BigNumber.from(purchase_amount).mul('1000000000000000000').toString(),
	  data: txData.data,
	  batchId: purchase_batchId,
	  batchNonce: nonce.add(1).toHexString(),
	  expiry: purchase_expiry,
	  txGas: purchase_txGas,
	  baseGas: 100000,
	  tokenGasPrice: BigNumber.from(purchase_tokenGasPrice * 1000000000).mul('1000000000').toString(), // TODO use decimals
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
		{name:"batchId",type:"uint256"},
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
	const provider = relayer.getProvider();
	const relayerWallet = new Wallet($relayer.privateKey).connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayerWallet);

	const currentBalance = await provider.getBalance(relayerWallet.address);
	if (currentBalance.lt('1000000000000000')) {
		$metatx = {status: 'error', message: 'relayer balance too low, please send ETH to ' + relayerWallet.address};
		return false;     
	}

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

	const actualMetaNonce = await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, purchase_batchId);
	const expectedBatchNonce = actualMetaNonce.add(1).toHexString();
	if (expectedBatchNonce != message.batchNonce) {
		$metatx = {status: 'error', message: 'Relayer will not execute it as the message has the wrong nonce'};
		return false;
	}
	console.log(expectedBatchNonce, message.batchNonce);

	let tx 
	try {
		tx = await metaTxProcessor.executeMetaTransaction(
			{
				from: message.from,
				to: message.to,
				data: message.data,
				signature: response,
				signatureType: 0
			},
			{
				tokenContract: message.tokenContract,
				amount: message.amount,
				batchId: message.batchId,
        		batchNonce: message.batchNonce,
        		expiry: message.expiry,
        		txGas: message.txGas,
        		baseGas: message.baseGas,
        		tokenGasPrice: message.tokenGasPrice,
        		relayer: message.relayer,
			},
			relayerWallet.address,
			{gasLimit: BigNumber.from('2000000'), chainId: relayer.getChainIdToUse()}
		);
	} catch(e) {
		// TODO error
		console.log(e);
		$metatx = {status: 'error', message: 'relayer tx failed at submission'};
		return false;
	}
	
	$metatx = {status: 'txBroadcasted'};
	await pause(0.4);
	let receipt;
	try {
		receipt = await tx.wait();
	} catch(e) {
		// TODO error
		console.log(e);
		$metatx = {status: 'error', message: 'relayer tx failed'};
		return false;
	}
	const metaTxEvent = receipt.events.find((event) => event.event === 'MetaTx' && event.address === metaTxProcessor.address);
	if (!metaTxEvent.args[2]){
		const errorString = errorToAscii(metaTxEvent.args[3]);
		$metatx = {status: 'error', message: 'MetaTx Mined but Error: ' + errorString};
		return false;
	}
	console.log(receipt);
	account.refresh();
	$metatx = {status: 'txConfirmed'};
	while($account.blockNumber < receipt.blockNumber) {
		await pause(0.5);
	}
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

<h2 class="center">Meta Tx Demo</h2>
<p>Welcome to the <a href="https://gitcoin.co/issue/MetaMask/Hackathons/2/3865">Take Back The Web Hackathon</a> Demo For a Meta Transaction Standard</p>
<p>This demo showcase the benefit of EIP-1776 standard and how it can be set up as a singleton contract that any contract can use to provide a seamingless experience to user without ether. More details <a href="about">here</a>.</p>
<hr/>
<WalletWrapper>
    <!-- <figure>
        <img alt='Borat' src='great-success.png'>
        <figcaption>HIGH FIVE!</figcaption>
    </figure> -->
	
	{#if $account.status == 'Loading'}
	<hr/>
    <p> fetching account info </p>
	<hr/>
	{:else if $account.status == 'Loaded'}
		<!-- <hr/> -->
		<p>MTX is a token that support our MetaTx standard and can thus be used without any extra step. You can even start interacting with contracts that support the standard and they can even charge tokens (no pre-approval required!).</p>
		<p>Your MTX Balance:</p>
		<hr/>
		<h3 class="center">{$account.mtxBalance.div('1000000000000000') / 1000}</h3>
		<hr/>
		<p>Here, for example, you can send a metatx to a NFT sale contract that expect to take from you 1 MTX in exchange of an NFT</p>
		<p><button on:click="{() => purchaseNumber()}">buy a Number for 1 MTX</button></p>
		<details>
			<summary>advanced Meta Tx settings</summary>
			<label>MTX amount</label><input type="number" bind:value={purchase_amount}/><br/>
			<label>expiry</label><input type="datetime" bind:value={purchase_expiry}/><br/>
			<label>txGas</label><input type="number" bind:value={purchase_txGas}/><br/>
			<label>batchId</label><input type="number" bind:value={purchase_batchId}/><br/>
			<label>nonce</label><input type="number" bind:value={purchase_nonce}/><br/>
			<label>tokenGasPrice</label><input type="number" bind:value={purchase_tokenGasPrice}/><br/>
			<label>relayer</label><input type="string" bind:value={purchase_relayer}/><br/>
		</details>
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
		<p>Here you can send a metatx to the NFT (ERC721) contract to transfer your token. (no need of MTX, unless you need to pay the relayer, see advanced settings))</p>
		<p><input placeholder="address" bind:value={transferTo}/></p>
		<p><button on:click="{() => transferFirstNumber()}">transfer</button></p>
		<details>
			<summary>advanced Meta Tx settings</summary>
			<label>MTX amount</label><input type="number" bind:value={transfer_amount}/><br/>
			<label>expiry</label><input type="datetime" bind:value={transfer_expiry}/><br/>
			<label>txGas</label><input type="number" bind:value={transfer_txGas}/><br/>
			<label>batchId</label><input type="number" bind:value={transfer_batchId}/><br/>
			<label>nonce</label><input type="number" bind:value={transfer_nonce}/><br/>
			<label>tokenGasPrice</label><input type="number" bind:value={transfer_tokenGasPrice}/><br/>
			<label>relayer</label><input type="string" bind:value={transfer_relayer}/><br/>
		</details>
		{/if}
	{:else if $account.status == 'Unavailable'}
	<span> please wait... <!--unlock account--> </span> <!-- temporary state, TODO synchronise flow -->
	{:else}
	<span> ERROR </span>
	{/if}
	
</WalletWrapper>


