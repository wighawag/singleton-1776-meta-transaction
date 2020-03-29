<script>
import wallet from '../stores/wallet';
import metatx from '../stores/metatx';
import relayer from '../stores/relayer';
import MessageBox from './MessageBox';

$: showModal = ($wallet && $wallet.status && $wallet.status !== 'Loading' && ((!$wallet.chainNotSupported && $relayer.status == 'Error') || $wallet.requestingSignature || $metatx.status != 'none'));

</script>

{#if $wallet.status == 'Loading'}
    <MessageBox> Please wait... </MessageBox>
{:else if $wallet.status == 'Locked'}
    <div class="bg-gray-200 overflow-hidden rounded-lg mt-3">
        <div class="px-4 py-5 sm:p-6">	
            <p>This demo requires you to have a wallet compatible with the EIP-712 standard. Please note that this has been tested only on Metamask.</p>
        </div>
    </div>

    <div class="text-center">
        <span class="inline-flex rounded-md shadow-sm mt-2">
            <button on:click="{wallet.unlock}" type="button" class="inline-flex items-center px-4 py-2 border border-transparent text-base leading-6 font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-500 focus:outline-none focus:border-indigo-700 focus:shadow-outline-indigo active:bg-indigo-700 transition ease-in-out duration-150">
                Connect your wallet
            </button>
        </span>
    </div>
    
{:else if $wallet.status == 'Unlocking'}
<MessageBox> Please accept the connection request </MessageBox>
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
    <button class="button" on:click="{() => wallet.retry()}">Retry</button>    
{:else if $wallet.status == 'Opera_Locked'}
<br/>
    <h3 class="errorTitle"> You are using Opera </h3>
    <h5 class="errorMessage"> You need to authorize access to your wallet. </h5>
    <button class="button" on:click="{() => wallet.retry()}">Request Access</button>
{:else if $wallet.status == 'Error'}
<br/>
    <h3 class="errorTitle"> There were an Error </h3>
    <h5 class="errorMessage">{$wallet.error.message}</h5>
    <button class="button" on:click="{() => wallet.retry()}">Retry</button>
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
            <button class="button" on:click="{() => wallet.reloadPage()}">Reload</button>
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


<!-- style="display:{((!$wallet.chainNotSupported && $relayer.status == 'Error') || $wallet.requestingSignature || $metatx.status != 'none') ? 'block' : 'none'}" -->
<!-- "{!((!$wallet.chainNotSupported && $relayer.status == 'Error') || $wallet.requestingSignature || $metatx.status != 'none')}" -->
<!-- class:hidden="{true}" -->
{#if showModal}
<div class="fixed bottom-0 inset-x-0 px-4 pb-6 sm:inset-0 sm:p-0 sm:flex sm:items-center sm:justify-center">
    <div class="fixed inset-0 transition-opacity">
      <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
    </div>
  
    <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-sm sm:w-full sm:p-6">
      <!-- <div>
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
          <svg class="h-6 w-6 text-green-600" stroke="currentColor" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
          </svg>
        </div> -->
        <div class="mt-3 text-center sm:mt-5">
            {#if !$wallet.chainNotSupported && $relayer.status == 'Error'}
                <div class="modal-content">
                <p>Unfortunately the fund for the relayers run has run out. If you can help please fund that address : {$relayer.funderAddress} and reload</p>
                </div>
            {:else if $metatx.status == 'error'}
                <div class="modal-content">
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
          <!-- <h3 class="text-lg leading-6 font-medium text-gray-900">
            Payment successful
          </h3>
          <div class="mt-2">
            <p class="text-sm leading-5 text-gray-500">
              Lorem ipsum dolor sit amet consectetur adipisicing elit. Consequatur amet labore.
            </p>
          </div> -->
        <!-- </div> -->
      </div>
      {#if $metatx.status == 'error'}
      <div class="mt-5 sm:mt-6">
        <span class="flex w-full rounded-md shadow-sm">
          <button on:click="{() => $metatx.status = 'none'}" type="button" class="inline-flex justify-center w-full rounded-md border border-transparent px-4 py-2 bg-red-600 text-base leading-6 font-medium text-white shadow-sm hover:bg-red-500 focus:outline-none focus:border-red-700 focus:shadow-outline-red transition ease-in-out duration-150 sm:text-sm sm:leading-5">
            OK
          </button>
        </span>
      </div>
      {/if}
      
    </div>
</div>
{/if}
