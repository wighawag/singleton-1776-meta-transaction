# Generalized Meta Transaction Processor with EIP-1776 Support

DEMO : [https://metatx.eth.link](https://metatx.eth.link)

You can find here an [EIP-1776](https://github.com/ethereum/EIPs/issues/1776) compliant Meta Transaction processor as a Singleton Contract

It is a full solution for meta-tx including relayer repayment that provides safety guarantees for both relayers and signers

Every recipient contract supporting this standard can receive Meta Transaction

Plus, by approving this smart contract on any ERC20 token, recipient can start receiving payments **without themselves being approved first**

As such new ERC20 token can have such contract pre-approved to provide a seamless user experience to their user. Alternatively, they can provide a `permit` call (a la DAI) to provide a similar experience, except for an extra relayed call. See the the [With DAI tab](dai)

Here a summary of its distinctive features:

*   Require minimum work for recipient. They simply need to check if msg.sender == singleton address
*   Supports Relayer refund in any ERC-20 tokens
*   Can send/allow ERC20 token transfer at the same time to the destination, without prior approval. This means you will not need any pre-approval step anymore
*   Allow you to specify an expiry time (combined with [EIP-1681](https://eips.ethereum.org/EIPS/eip-1681), this allow relayer and user to ensure they get their tx in or not after a certain time, no more guessing)
*   Ensure the user its tx will be executed with the specific gas specified (though [EIP-1930](https://eips.ethereum.org/EIPS/eip-1930) would be better). While an obvious feature, this has been badly implemented in almost all other meta transaction implementation out there, including GSN and Gnosis Safe (see [https://github.com/gnosis/safe-contracts/issues/100](https://github.com/gnosis/safe-contracts/issues/100)).
*   Can provide a mechanism by which relayer / user can coordinate to ensure no 2 relayer submit the same meta-tx at the same time at the expense of one)
*   Use a 2 dimensional nonce, allowing to group transaction in or out of order. This allow user to for example make a ordered batch of transaction in one application and still remains able to do another ordered batch in another application.

## Implementation Choices

We can categorize meta-transaction support in at least, 6 different dimensions and here we will examine for each, the reasoning behind the choice

### A) Type of implementation

There are roughly 4 type of implementation

*   **Account-contract Based** (a la Gnosis Safe, etc…) where recipient do not need any modification but that require user to get a deployed account contract.
*   **Singleton Proxy** where the recipient simply need to check for the singleton address and where all the logic of meta transaction is implemented in the singleton. It can support charging with tokens and even provide token payments
*   **Token Proxy** where the recipient simply need to check for the token address and where all the logic of meta transaction is implemented in the token. This is the approach originally taken by @austingriffith in “Native Meta Transaction”. It is usually limited to be used for meta-tx to be paid in the specific token. Relayer would then need to trust each token for repayment.
*   **No Proxy** where the recipient is the meta-tx processor and where all the logic get implemented. While it can support relayer repayment, relayer would have to somehow trust each recipient implementation.

While [EIP-1776](https://github.com/ethereum/EIPs/issues/1776) is compatible with any of them, the demo use the singleton proxy pattern. This is for 3 reasons:

*   1) we want to support EOA signer so Account-contract is not an option
*   2) The whole meta-tx intricacies can be solved in one contract
*   3) Users and Relayers (that expect refund) only need to trust one implementation

### B) Relayer refund

Another differentiation is the ability of relayer to get paid.

In our opinion, It is such an important feature for relayers that we should ensure it is at least possible to implement it on top, if not already present.

In that regard one thing that becomes important as soon as a relayer get paid, is that there is a mechanism to ensure the relayer cannot make the meta-tx fails. hence the need for txGas in [EIP-1776](https://github.com/ethereum/EIPs/issues/1776).

Another important EIP that would help here is [EIP-1930](https://eips.ethereum.org/EIPS/eip-1930) as the EVM call have poor support for passing an exact amount of gas to a call.

It is also worth noting the importance of the `baseGas` parameter here too, as this make our implementation independent of opcode pricing while ensuring the relayer can account for the extra gas required to execute the meta transaction processing cost. Other implementation like GSN hardcode values in their contract, which is vulnerable to opcode pricing changes

Note that while it is possible to implement the refund on top of the proposal, as soon as we want the user to pay for the meta-tx (in a token for example), we will have to request yet another signature. We find it would be much convenient to have it implemented here. It is always possible for user to set a tokenGasPrice of zero if they have access to a repayer

### C) Token Transfer / Approval

While relayer-refund can be on its own, we found that it is trivial to also add the ability for meta-transaction processors to support transfering tokens to recipient.

This is a very powerful feature as it remove the need to pre-approve recipient, if they already support meta-tx.

### D) MetaTx Signer Verification

Finally, another differentation possible for non-account based meta transaction is how the signer is being picked up by the recipient.

In [EIP-1776](https://github.com/ethereum/EIPs/issues/1776) we assume that recipient can easily add a from field to their functions as this is already a common practice in many standard.

The standard could easily be changed to support a different mechanism, like appending the signer address to the end of the call data.

### E) meta tx failure responsibility

Earlier meta tx implementation assumed that the relayer was responsible of ensuring that the meta transaction call would not fails. So that when it fails, the whole tx would revert and the relayer would not get its refund if any.

This is in our opinion, not a great idea as this complexify the role of the relayer, since it has to guess whether the meta-tx call will not fails for reason out of its knowledge.

As such, we decided to add the `txGas` parameter that dictate how much gas need to be passed into the meta-tx call. If not enough is passed in the relayer's tx revert, causing relayer to lose its gas.

While this seems trivial to implement, this is not the case and almost every meta transaction implementation out there fails to implement it properly

They all seems to believe that the gas parameter passed to the various CALL opcode are a specific gas amount. This is not the case and the gas value only act as a maximum value unfortunately. To my knowledge, we are the first to implement correctly. Unfortunately in order to remain opcode pricing independent we relies on the specific behavior of [EIP-150](https://eips.ethereum.org/EIPS/eip-150) 63/64 rules to do so. The proper way to fix it for all meta transaction implementation would be to get [EIP-1930](https://eips.ethereum.org/EIPS/eip-1930) accepted in the next hard fork.

### F) Nonce support

There are different strategy to ensure tx cannot get replayed. The simplest one, used by ethereum is to simply have an increasing nonce

[EIP-1776](https://github.com/ethereum/EIPs/issues/1776)provide a 2 dimensional nonce system allowing user to group meta-tx in batches independently of each other

This allows user to create and submit simultaneously multiple batch of ordered meta-tx

## Multi Relayer Coordination

In order to avoid the possibilities of relayers submitting 2 meta-tx with the same nonce, at the expense of the relayer getting tis tx included later, the proposal offer a mechanism to avoid it.

Every meta-tx can include a relayer field. This field has 2 purpose, teh obvious one is to limit the message to be used by a specific relayer. the second is to ensure the relayer that if teh tx get included it get a reward for inclusion

Relayer can thus reject any meta-tx that do not specify their relayer address so that user are incentivized to only submit one tx at a time, or run the risk of paying teh cost of the extra relayed tyx.

Of course, if the user got rid of its payment token as part of one of this competing tx, the user remains safe and one of the relayer will not get its refund, so this is not full proof.

Also this is not implemented in the demo.