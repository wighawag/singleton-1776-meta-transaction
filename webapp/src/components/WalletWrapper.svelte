<script>
import wallet from '../stores/wallet';
import metatx from '../stores/metatx';
import relayer from '../stores/relayer';
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

h3 {
    text-align: center;
}
p {
    text-align: center;
}
.wrapper {
    text-align: center;
}
.wrapper ul {
    display: inline-block;
    margin: 0;
    padding: 0;
    /* For IE, the outcast */
    zoom:1;
    *display: inline;
}
.wrapper li {
    padding: 2px 5px;
}
</style>
{#if $wallet.status == 'Loading'}
<br/>
    <h3> Please wait... </h3>
{:else if $wallet.status == 'Locked'}
<br/>
    <p>This demo requires you to have a wallet compatible with the EIP-712 standard. Please note that this has been tested only on Metamask.</p>
    <p><button on:click="{wallet.unlock}">Connect your wallet</button></p>
{:else if $wallet.status == 'Unlocking'}
<br/>
    <h3> Please accept the connection request </h3>
{:else if $wallet.status == 'NoWallet'}
<br/>
  <h3>You need a web3 wallet</h3>
{:else if $wallet.status == 'CreatingLocalWallet'}
<br/>
    <h3>Creating Local Wallet</h3>
{:else if $wallet.status == 'Opera_FailedChainId'}
<br/>
    <h3 class="errorTitle"> You are using Opera </h3>
    <h5 class="errorMessage">You need to set up your wallet. if a popup did not come up you'll need to go into Opera setting to set it up.</h5>
    <button on:click="{() => wallet.retry()}">Retry</button>    
{:else if $wallet.status == 'Opera_Locked'}
<br/>
    <h3 class="errorTitle"> You are using Opera </h3>
    <h5 class="errorMessage"> You need to authorize access to your wallet. </h5>
    <button on:click="{() => wallet.retry()}">Request Access</button>
{:else if $wallet.status == 'Error'}
<br/>
    <h3 class="errorTitle"> There were an Error </h3>
    <h5 class="errorMessage">{$wallet.error.message}</h5>
    <button on:click="{() => wallet.retry()}">Retry</button>
{:else if $wallet.status == 'Ready'}
    {#if $wallet.chainNotSupported}
    <br/>
        <h3 class="errorTitle"> You are on an unsupported chain</h3>
        {#if $wallet.supportedChains.length == 1}
        <h3> Please change your chain to {$wallet.supportedChains[0].name}</h3>
        {:else}
        <h3> Please change your chain to either</h3>
        <div class="wrapper">
        <ul>
        {#each $wallet.supportedChains as chain}
        <li>{chain.name}</li>
        {/each}
        </ul>
        </div>
        {/if}
        {#if $wallet.requireManualChainReload }
            <h5 class="errorMessage">You might need to reload the page after switching to the new chain</h5>
            <button on:click="{() => wallet.reloadPage()}">Reload</button>
        {/if}
    {:else if typeof $wallet.initialBalance !== 'undefined' && $wallet.initialBalance == 0}
    <br/>
        <h3> You have zero balance</h3>
    {:else}
        <!-- {#if $wallet.requestingSignature}
            <h3> Please accept the transaction request </h3>
        {:else} -->
        <slot></slot>    
        <!-- {/if} -->
    {/if}
{/if}

<div id="myModal" class="modal" style="display:{((!$wallet.chainNotSupported && $relayer.status == 'Error') || $wallet.requestingSignature || $metatx.status != 'none') ? 'block' : 'none'}">
    <!-- Modal content -->
    {#if !$wallet.chainNotSupported && $relayer.status == 'Error'}
        <div class="modal-content">
        <p>Unfortunately the fund for the relayers run has run out. If you can help please fund that address : {$relayer.funderAddress} and reload</p>
        </div>
    {:else if $metatx.status == 'error'}
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
            <p>waiting for relay tx to be mined (it can take a while)...</p>
            {:else if $metatx.status == 'txConfirmed'}
            <p>tx confirmed, please wait...</p>
            {:else}
            <p>Please accept signature</p>
            {/if}
        </div>
    {/if}
</div>

