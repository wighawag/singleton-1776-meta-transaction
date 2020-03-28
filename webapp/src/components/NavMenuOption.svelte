<script>
    export let selected = false;
    export let href;
</script>

{#if selected}
<a {href} on:click class="block px-3 py-2 rounded-md text-base font-medium text-white bg-gray-900 focus:outline-none focus:text-white focus:bg-gray-700 transition duration-150 ease-in-out">
    <slot></slot>
</a>
{:else}
<a {href} on:click class="mt-1 block px-3 py-2 rounded-md text-base font-medium text-gray-300 hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700 transition duration-150 ease-in-out">
    <slot></slot>
</a>
{/if}
