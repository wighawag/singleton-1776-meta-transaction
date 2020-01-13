<script>
import wallet from '../stores/wallet';
import WalletWrapper from '../components/WalletWrapper';
import account from '../stores/account';
import * as ethers from 'ethers';

const { Wallet, Contract, BigNumber, AbiCoder } = ethers;

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
	const txData = await wallet.computeData('Numbers', 'transferFrom', $wallet.address, transferTo, $account.numbers[0]);
	const nonce = await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, 0);

	const message = {
      from: $wallet.address,
	  to: nftAddress,
	  tokenContract: daiAddress,
	  amount: 0,
	  data: txData.data,
	  batchNonce: nonce.toNumber() + 1,
	  expiry: "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	  txGas: 1000000,
	  baseGas: 100000,
	  tokenGasPrice: 0,
	  relayer: "0x0000000000000000000000000000000000000000",
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
	
	const response = await wallet.sign(msgParams);

	const provider = wallet.getFallbackProvider();
	const relayer = new Wallet('0xf912c020908da6935d420274cb1fa5fe609296ee3898bc190608a8d836463e26').connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayer);

	const tx = await metaTxProcessor.executeERC20MetaTx(
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
		relayer.address,
		0,
		{gasLimit: BigNumber.from('2000000'), chainId: 1} // chainId = 1 is required for ganache
	);
	console.log(tx);
	const receipt = await tx.wait();
	const events = await getEventsFromReceipt(provider, metaTxProcessor,"MetaTx(address,uint256,bool,bytes)" , receipt);
	// console.log(ethers.utils.defaultAbiCoder.decode(['Error(srtring)'],events[0].values[3]));
	// console.log(ethers.utils.toUtf8String(events[0].values[3]));
	if(!events[0].values[2]) {
		console.log(errorToAscii(events[0].values[3]));
	}
	console.log(receipt);
	return receipt;
}

async function purchaseNumber() {
	const saleAddress = wallet.getContract('NumberSale').address;
	const daiAddress = wallet.getContract('DAI').address;
	const metaTxProcessorContract = wallet.getContract('GenericMetaTxProcessor');
	const metaTxProcessorAddress = metaTxProcessorContract.address;
	const txData = await wallet.computeData('NumberSale', 'purchase', $wallet.address, $wallet.address);
	const nonce = await wallet.call('GenericMetaTxProcessor', 'meta_nonce', $wallet.address, 0);

	const message = {
      from: $wallet.address,
	  to: saleAddress,
	  tokenContract: daiAddress,
	  amount: '1000000000000000000',
	  data: txData.data,
	  batchNonce: nonce.toNumber() + 1,
	  expiry: "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	  txGas: 1000000,
	  baseGas: 100000,
	  tokenGasPrice: 0,
	  relayer: "0x0000000000000000000000000000000000000000",
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
	
	const response = await wallet.sign(msgParams);

	const provider = wallet.getFallbackProvider();
	const relayer = new Wallet('0xf912c020908da6935d420274cb1fa5fe609296ee3898bc190608a8d836463e26').connect(provider);
	const metaTxProcessor = new Contract(metaTxProcessorContract.address, metaTxProcessorContract.abi, relayer);

	const tx = await metaTxProcessor.executeERC20MetaTx(
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
		relayer.address,
		0,
		{gasLimit: BigNumber.from('2000000'), chainId: 1} // chainId = 1 is required for ganache
	);
	const receipt = await tx.wait();
	if(!events[0].values[2]) {
		console.log(errorToAscii(events[0].values[3]));
	}
	console.log(receipt);
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
	
	const response = await wallet.sign(msgParams);
	const splitSig = ethers.utils.splitSignature(response);

	const provider = wallet.getFallbackProvider();
	const relayer = new Wallet('0xf912c020908da6935d420274cb1fa5fe609296ee3898bc190608a8d836463e26').connect(provider);
	const DAI = new Contract(dai.address, dai.abi, relayer);

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
	console.log(tx);
	const receipt = await tx.wait();
	console.log(receipt);
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

	@media (min-width: 480px) {
		h1 {
			font-size: 4em;
		}
	}
</style>

<svelte:head>
	<title>Sapper project template</title>
</svelte:head>

<WalletWrapper>
    <h2>Meta Tx Demo</h2>
    <!-- <figure>
        <img alt='Borat' src='great-success.png'>
        <figcaption>HIGH FIVE!</figcaption>
    </figure> -->

	
	<hr/>
	account
	<hr/>
	{#if $account.status == 'Loading'}
    <span> fetching account info </span>
	{:else if $account.status == 'Loaded'}
		<p>Your DAI Balance:</p>
		<p>{$account.daiBalance.div('1000000000000000000')}</p>
		{#if $account.hasApprovedMetaTxProcessorForDAI}
		<button on:click="{() => purchaseNumber()}">buy a Number for 1 DAI</button>
		{:else}
		<p>In order to purchase the Numbers NFT you first need to approve the MetaTx Processor to transfer DAI on your behalf.</p>
		<p><button on:click="{() => permitDAI()}">Approve MetaTx Processor</button></p>
		{/if}
		<br/>
		<br/>
		<hr/>
		<h3>Your Numbers NFT below :</h3>
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
		<p>Transfer your first Number</p>
		<p><input placeholder="address" bind:value={transferTo}/></p>
		<p><button on:click="{() => transferFirstNumber()}">transfer</button></p>
		
		{/if}
	{:else if $account.status == 'Unavailable'}
	<span> please unlock account </span>
	{:else}
	<span> ERROR </span>
	{/if}
	
</WalletWrapper>


