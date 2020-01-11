<script>
import wallet from '../stores/wallet';
</script>

{#if $wallet.status == 'Loading'}
    <h3> Please wait... </h3>
{:else if $wallet.status == 'Locked'}
    <button on:click="{wallet.unlock}"> Connect your wallet</button>
{:else if $wallet.status == 'Unlocking'}
    <h3> Please accept the connection request </h3>
{:else if $wallet.status == 'NoWallet'}
  <h3>You need a web3 wallet</h3>
{:else if $wallet.status == 'CreatingLocalWallet'}
    <h3>Creating Local Wallet</h3>
{:else if $wallet.status == 'Opera_FailedChainId'}
    <h3 class="errorTitle"> You are using Opera </h3>
    <h5 class="errorMessage">You need to set up your wallet. if a popup did not come up you'll need to go into Opera setting to set it up.</h5>
    <button on:click="{() => wallet.retry()}">Retry</button>    
{:else if $wallet.status == 'Opera_Locked'}
    <h3 class="errorTitle"> You are using Opera </h3>
    <h5 class="errorMessage"> You need to authorize access to your wallet. </h5>
    <button on:click="{() => wallet.retry()}">Request Access</button>
{:else if $wallet.status == 'Error'}
    <h3 class="errorTitle"> There were an Error </h3>
    <h5 class="errorMessage">{$wallet.error.message}</h5>
    <button on:click="{() => wallet.retry()}">Retry</button>
{:else if $wallet.status == 'Ready'}
    {#if $wallet.chainNotSupported}
        <h3> Please change your network </h3>
        {#if $wallet.requireManualChainReload }
            <h5 class="errorMessage">You might need to reload the page after switching to the new chain</h5>
            <button on:click="{() => wallet.reloadPage()}">Reload</button>
        {/if}
    {:else if typeof $wallet.initialBalance !== 'undefined' && $wallet.initialBalance == 0}
        <h3> You have zero balance</h3>
    {:else}
        {#if $wallet.requestingTx}
            <h3> Please accept the transaction request </h3>
        {:else}
        <slot></slot>    
        {/if}
    {/if}
{/if}