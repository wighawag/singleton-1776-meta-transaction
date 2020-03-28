<script>
    export let label;
    export let type;
    export let value;
</script>
<div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:items-start sm:border-t sm:border-gray-200 sm:pt-5 m-2 mb-3">
    <label for="value" class="block text-sm font-medium leading-5 text-gray-700 sm:mt-px sm:pt-2 m-1">
    {label}
    </label>
    <div class="mt-1 sm:mt-0 sm:col-span-2 m-1">
        <div class="max-w-lg flex rounded-md shadow-sm">
            {#if type == 'number'}
            <input id="value" type="number" bind:value={value} class="flex-1 form-input block w-full rounded-none rounded-r-md transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            {:else if type == 'string'}
            <input id="value" type="string" bind:value={value} class="flex-1 form-input block w-full rounded-none rounded-r-md transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            {:else if type == 'datetime'}
            <input id="value" type="datetime" bind:value={value} class="flex-1 form-input block w-full rounded-none rounded-r-md transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            {:else}
            <input id="value" bind:value={value} class="flex-1 form-input block w-full rounded-none rounded-r-md transition duration-150 ease-in-out sm:text-sm sm:leading-5" />
            {/if}
        </div>
    </div>
</div>