<script>
    export let selected = false;
    export let href;
</script>

{#if selected}
<a {href} class="ml-4 px-3 py-2 rounded-md text-sm font-medium leading-5 text-white bg-gray-900 focus:outline-none focus:text-white focus:bg-gray-700 transition duration-150 ease-in-out">
    <slot></slot>
</a>
{:else}
<a {href} class="ml-4 px-3 py-2 rounded-md text-sm font-medium leading-5 text-gray-300 hover:text-white hover:bg-gray-700 focus:outline-none focus:text-white focus:bg-gray-700 transition duration-150 ease-in-out">
    <slot></slot>
</a>
{/if}
