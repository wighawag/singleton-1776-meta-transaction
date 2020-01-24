<svelte:head>
	<title>About Meta Tx Demo</title>
</svelte:head>

<h1>About Meta Tx Demo</h1>

<p>This demo shows case an <a href="https://github.com/ethereum/EIPs/issues/1776">EIP-1776</a> compliant Meta Transaction processor as a Singleton Contract</p>

<p>It is a full solution for meta-tx including relayer repayment that provides safety guarantees for both relayers and signers</p>

<p>Every recipient contract supporting this standard can receive Meta Transaction</p>

<p>Plus, by approving this smart contract on any ERC20 token, recipient can start receiving payments <strong>without themselves being approved first</strong></p>

<p>As such new ERC20 token can have such contract pre-approved to provide a seamless user experience to their user. Alternatively, they can provide a `permit` call (a la DAI) to provide a similar experience, except for an extra relayed call. See the the <a href="dai">With DAI tab</a></p>

<p>Here a summary of its distinctive features:</p>

<ul>
<li>Require minimum work for recipient. They simply need to check if msg.sender == singleton address</li>
<li>Supports Relayer refund in any ERC-20 tokens</li>
<li>Can send/allow ERC20 token transfer at the same time to the destination, without prior approval. This means you will not need any pre-approval step anymore</li>
<li>Allow you to specify an expiry time (combined with <a href="https://eips.ethereum.org/EIPS/eip-1681">EIP-1681</a>, this allow relayer and user to ensure they get their tx in or not after a certain time, no more guessing)</li>
<li>Ensure the user its tx will be executed with the specific gas specified (though <a href="https://eips.ethereum.org/EIPS/eip-1930">EIP-1930</a> would be better). While an obvious feature, this has been badly implemented in almost all other meta transaction implementation out there, including GSN and Gnosis Safe (see <a href="https://github.com/gnosis/safe-contracts/issues/100">https://github.com/gnosis/safe-contracts/issues/100</a>).</li>
<li>Can provide a mechanism by which relayer / user can coordinate to ensure no 2 relayer submit the same meta-tx at the same time at the expense of one)</li>
<li>Use a 2 dimensional nonce, allowing to group transaction in or out of order. This allow user to for example make a ordered batch of transaction in one application and still remains able to do another ordered batch in another application.</li>
</ul>

<h2>Implementation Choices</h2>
<p>We can categorize meta-transaction support in at least, 6 different dimensions and here we will examine for each, the reasoning behind the choice</p>

<h3>A) Type of implementation </h3>
<p>There are roughly 4 type of implementation</p>
<ul>
<li><strong>Account-contract Based</strong> (a la Gnosis Safe, etc…) where recipient do not need any modification but that require user to get a deployed account contract.</li>
<li><strong>Singleton Proxy</strong> where the recipient simply need to check for the singleton address and where all the logic of meta transaction is implemented in the singleton. It can support charging with tokens and even provide token payments</li>
<li><strong>Token Proxy</strong> where the recipient simply need to check for the token address and where all the logic of meta transaction is implemented in the token. This is the approach originally taken by @austingriffith in “Native Meta Transaction”. It is usually limited to be used for meta-tx to be paid in the specific token. Relayer would then need to trust each token for repayment.</li>
<li><strong>No Proxy</strong> where the recipient is the meta-tx processor and where all the logic get implemented. While it can support relayer repayment, relayer would have to somehow trust each recipient implementation.</li>
</ul>

<p>While <a href="https://github.com/ethereum/EIPs/issues/1776">EIP-1776</a> is compatible with any of them, the demo use the singleton proxy pattern. This is for 3 reasons:</p>
<ul>
	<li>1) we want to support EOA signer so Account-contract is not an option</li>
	<li>2) The whole meta-tx intricacies can be solved in one contract</li>
	<li>3) Users and Relayers (that expect refund) only need to trust one implementation</li>
</ul>

<h3>B) Relayer refund</h3>
<p>Another differentiation is the ability of relayer to get paid.</p>
<p>In our opinion, It is such an important feature for relayers that we should ensure it is at least possible to implement it on top, if not already present.</p>
<p>In that regard one thing that becomes important as soon as a relayer get paid, is that there is a mechanism to ensure the relayer cannot make the meta-tx fails. hence the need for txGas in <a href="https://github.com/ethereum/EIPs/issues/1776">EIP-1776</a>.</p>
<p>Another important EIP that would help here is <a href="https://eips.ethereum.org/EIPS/eip-1930">EIP-1930</a> as the EVM call have poor support for passing an exact amount of gas to a call.</p>

<p>It is also worth noting the importance of the `baseGas` parameter here too, as this make our implementation independent of opcode pricing while ensuring the relayer can account for the extra gas required to execute the meta transaction processing cost. Other implementation like GSN hardcode values in their contract, which is vulnerable to opcode pricing changes</p>

<p>Note that while it is possible to implement the refund on top of the proposal, as soon as we want the user to pay for the meta-tx (in a token for example), we will have to request yet another signature. We find it would be much convenient to have it implemented here. It is always possible for user to set a tokenGasPrice of zero if they have access to a repayer</p>

<h3>C) Token Transfer / Approval</h3>
<p>While relayer-refund can be on its own, we found that it is trivial to also add the ability for meta-transaction processors to support transfering tokens to recipient.</p>
<p>This is a very powerful feature as it remove the need to pre-approve recipient, if they already support meta-tx.</p>

<h3>D) MetaTx Signer Verification</h3>
<p>Finally, another differentation possible for non-account based meta transaction is how the signer is being picked up by the recipient.</p>

<p>In <a href="https://github.com/ethereum/EIPs/issues/1776">EIP-1776</a> we assume that recipient can easily add a from field to their functions as this is already a common practice in many standard.</p>
<p>The standard could easily be changed to support a different mechanism, like appending the signer address to the end of the call data.</p>

<h3>E) meta tx failure responsibility</h3>
<p>Earlier meta tx implementation assumed that the relayer was responsible of ensuring that the meta transaction call would not fails. So that when it fails, the whole tx would revert and the relayer would not get its refund if any.</p>
<p>This is in our opinion, not a great idea as this complexify the role of the relayer, since it has to guess whether the meta-tx call will not fails for reason out of its knowledge.</p>
<p>As such, we decided to add the `txGas` parameter that dictate how much gas need to be passed into the meta-tx call. If not enough is passed in the relayer's tx revert, causing relayer to lose its gas.</p>
<p>While this seems trivial to implement, this is not the case and almost every meta transaction implementation out there fails to implement it properly</p>
<p>They all seems to believe that the gas parameter passed to the various CALL opcode are a specific gas amount. This is not the case and the gas value only act as a maximum value unfortunately. To my knowledge, we are the first to implement correctly. Unfortunately in order to remain opcode pricing independent we relies on the specific behavior of <a href="https://eips.ethereum.org/EIPS/eip-150">EIP-150</a> 63/64 rules to do so. The proper way to fix it for all meta transaction implementation would be to get <a href="https://eips.ethereum.org/EIPS/eip-1930">EIP-1930</a> accepted in the next hard fork.</p>

<h3>F) Nonce support</h3>

<p>There are different strategy to ensure tx cannot get replayed. The simplest one, used by ethereum is to simply have an increasing nonce</p>

<p><a href="https://github.com/ethereum/EIPs/issues/1776">EIP-1776</a>provide a 2 dimensional nonce system allowing user to group meta-tx in batches independently of each other</p>
<p>This allows user to create and submit simultaneously multiple batch of ordered meta-tx</p>

<h2>Batching calls in one meta-tx</h2>

<p>While the batch/nonce feature allow you to batch tx in order and keep your ability to create transaction that have high gas requirement, they still require user to sign multiple meta-transaction and wait for the relayers to submit all of them.</p>
<p>We added a special function in the processor that can be invoked as a meta-transaction itself so users can batch multiple calls in one meta-tx without any change to EIP-1776 format.</p>
<p>They simply make a sign message with the call data and destination (and gas) for each call they want to make and submit this as a call to that specific function.</p>
<p>see <a href="https://github.com/wighawag/singleton-1776-meta-transaction/blob/24fe66e0c40f7c4b2d23b29994e7ef3b3a5f29e2/contracts/src/GenericMetaTxProcessor.sol#L289">here</a></p>


<h2>Multi Relayer Coordination</h2>

<p>In order to avoid the possibilities of relayers submitting 2 meta-tx with the same nonce, at the expense of the relayer getting tis tx included later, the proposal offer a mechanism to avoid it.</p>

<p>Every meta-tx can include a relayer field. This field has 2 purpose, the obvious one is to limit the message to be used by a specific relayer. the second is to ensure the relayer that if the tx get included it get a reward for inclusion</p>
<p>Relayer can thus reject any meta-tx that do not specify their relayer address so that user are incentivized to only submit one tx at a time, or run the risk of paying the cost of the extra relayed tyx.</p>

<p>Of course, if the user got rid of its payment token as part of one of this competing tx, the user remains safe and one of the relayer will not get its refund, so this is not full proof.</p>

<p>Also this is not implemented in the demo.</p>
