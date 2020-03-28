<script>
	import Tailwindcss from '../components/Tailwindcss.svelte';
	import Nav from '../components/Nav.svelte';

	export let segment;
</script>

<Tailwindcss />
<style global >
	.button {
		/* hover:text-white hover:bg-purple-500 */
		@apply text-purple-500 border border-purple-500 text-xs font-semibold rounded-full px-4 py-1 leading-normal
	}
</style>

<Nav {segment}/>

<main class="container mx-auto">
	<slot></slot>
</main>