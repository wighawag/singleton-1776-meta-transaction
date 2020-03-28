<script>
	export let segment;
</script>

<nav>
	<ul>
		<li><a class:selected='{segment === undefined}' href='.'>MTX</a></li>
		<li><a class:selected='{segment === "dai"}' href='dai'>With DAI</a></li>
		<!-- <li><a class:selected='{segment === "relayer"}' href='relayer'>relayer</a></li> -->

		<li><a class:selected='{segment === "about"}' href='about'>About</a></li>
		
		<!-- for the blog link, we're using rel=prefetch so that Sapper prefetches
		    the blog data when we hover over the link or tap it on a touchscreen -->
		<!-- <li><a rel=prefetch class:selected='{segment === "blog"}' href='blog'>blog</a></li> -->
	</ul>
</nav>
