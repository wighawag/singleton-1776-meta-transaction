## A Singleton MetaTx Processor using EIP-1776 that support all ERC20 tokens

Here you'll find a EIP-1776 compliant generic meta transaction processor.

If a user approve this contract, it can start performing meta-tx on contracts that supports it.

For DAI, this would require a simple signature and the call to `permit`

The contract has also the ability to transfer the approved token by simply signing a meta-tx.

The `amount` field allow the meta tx contract to approve the amount to be used by receiver but unfortunatelythis cannot be greater than zero when data is being passed.
This is because the `approve` function of ERC20 need to be called by the owner and cannot be executed by an `operator`

If this was possible, the meta tx processor could automatically approve the receiver so user do not need to pre-approve.

This is still part of EIP-1776 as the standard also support individual token contract implementing native meta transacion that allows them to support such feature

