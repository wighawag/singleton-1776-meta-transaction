<svelte:head>
	<title>About Meta Tx Demo</title>
</svelte:head>

<h1>About Meta Tx Demo</h1>

<p>This demo shows case the EIP-1776 compliant Generic Meta Tx Contract</p>

<p>By approving this smart contract on any ERC20 token, you can start executing meta transaction</p>


<p>Here are few distinctive features:</p>

<ul>
<li>can send ERC20 token in the same time to the destination, without prior approval. This means you will not need any pre-approval step anymore</li>
<li>allow you to specify an expiry time (combined with EIP-1681, this allow relayer and user to ensure they get their tx in or not after a certain time, no more guessing)</li>
<li>Require very little integration on the reciving end. For ERC-20, ERC-721 or ERC-1155 they can reuse their transferFrom functions</li>
<li>Ensure the user its tx will be executed with the specific gas specified (though EIP-1930 would be better)</li>
</ul>