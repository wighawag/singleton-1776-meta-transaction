<script>
import wallet from '../stores/wallet';
import metatx from '../stores/metatx';
</script>

<style>
/* The Modal (background) */
.modal {
  display: none; /* Hidden by default */
  position: fixed; /* Stay in place */
  z-index: 1; /* Sit on top */
  left: 0;
  top: 0;
  width: 100%; /* Full width */
  height: 100%; /* Full height */
  overflow: auto; /* Enable scroll if needed */
  background-color: rgb(0,0,0); /* Fallback color */
  background-color: rgba(0,0,0,0.4); /* Black w/ opacity */
}

/* Modal Content/Box */
.modal-content {
  text-align:center;
  background-color: #fefefe;
  margin: 15% auto; /* 15% from the top and centered */
  padding: 20px;
  border: 1px solid #888;
  width: 80%; /* Could be more or less, depending on screen size */
}

/* The Close Button */
.close {
  color: #aaa;
  float: right;
  font-size: 28px;
  font-weight: bold;
}

.close:hover,
.close:focus {
  color: black;
  text-decoration: none;
  cursor: pointer;
}
</style>

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
        <!-- {#if $wallet.requestingSignature}
            <h3> Please accept the transaction request </h3>
        {:else} -->
        <slot></slot>    
        <!-- {/if} -->
    {/if}
{/if}

<div id="myModal" class="modal" style="display:{($wallet.requestingSignature || $metatx.status != 'none') ? 'block' : 'none'}">
    <!-- Modal content -->
    {#if $metatx.status == 'error'}
        <div class="modal-content">
        <span class="close" on:click="{() => $metatx.status = 'none'}">&times;</span>
        <p>{$metatx.message}</p>
        </div>
    {:else}
        <div class="modal-content">
            {#if $metatx.status == 'submitting'}
            <p>submiting to relayer...</p>
            {:else if $metatx.status == 'waitingRelayer'}
            <p>waiting for relayer...</p>
            {:else if $metatx.status == 'txBroadcasted'}
            <p>waiting for relay tx to be mined...</p>
            {:else}
            <p>Please accept signature</p>
            {/if}
        </div>
    {/if}
</div>
