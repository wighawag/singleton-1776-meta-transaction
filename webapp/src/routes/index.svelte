<script>
import wallet from '../stores/wallet';
import WalletWrapper from '../components/WalletWrapper';

async function signMessage() {
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
		{name:"data",type:"bytes32"},
		{name:"nonce",type:"uint256"},
		{name:"minGasPrice",type:"uint256"},
		{name:"txGas",type:"uint256"},
		{name:"baseGas",type:"uint256"},
		{name:"tokenGasPrice",type:"uint256"},
        {name:"relayer",type:"address"}
      ],
    },
    primaryType:"ERC20MetaTransaction",
    domain:{name:"Generic Meta Transaction",version:"1",verifyingContract: wallet.getContract('GenericMetaTxProcessor').address},
    message:{
      from: $wallet.address,
	  to: "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
	  tokenContract: wallet.getContract('ExampleReceiver').address,
	  amount: 0,
	  data: "0x", // TODO
	  nonce: 0,
	  minGasPrice: 0,
	  txGas: 100000,
	  baseGas: 100000,
	  tokenGasPrice: 0,
	  relayer: "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
	}});
	
	const response = await wallet.sign(msgParams);
	console.log({response});
	return response;
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
    <h1>Great success!</h1>
    <figure>
        <img alt='Borat' src='great-success.png'>
        <figcaption>HIGH FIVE!</figcaption>
    </figure>

	<button on:click="{() => signMessage()}">Sign MetaTx</button>
</WalletWrapper>


