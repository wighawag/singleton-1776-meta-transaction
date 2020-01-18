<svelte:head>
	<title>About Meta Tx Demo</title>
</svelte:head>

<h1>About Meta Tx Demo</h1>

<p>This demo shows case an EIP-1776 compliant Metatx processor as Singleton</p>

<p>Every recipient contract supporting the standard can receive Meta Transaction</p>

<p>Plus, by approving this smart contract on any ERC20 token, recipient can start receiving payments without themselves being approved first</p>

<p>As such new ERC20 token can have such contract pre-approved to provide a seamless user experience to their user. Alternativively, they can provide a `permit` call (a la DAI) to provide a similar experience, except for an extra relayed call.</p>

<p>Here a summary of its distinctive features:</p>

<ul>
<li>Require minimum work for recipient. They simply need to check if msg.sender == singleton adress</li>
<li>Supports Relayer refund in any tokens</li>
<li>can send ERC20 token in the same time to the destination, without prior approval. This means you will not need any pre-approval step anymore</li>
<li>allow you to specify an expiry time (combined with EIP-1681, this allow relayer and user to ensure they get their tx in or not after a certain time, no more guessing)</li>
<li>Ensure the user its tx will be executed with the specific gas specified (though EIP-1930 would be better)</li>
</ul>