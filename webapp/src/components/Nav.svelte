<script>
	import NavTab from './NavTab';
	import NavMenuOption from './NavMenuOption';
	export let segment;

	let open = false
</script>

<nav class="bg-gray-800">
  <!-- default -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
	<div class="flex items-center justify-between h-16">
      <div class="flex items-center">

		<!-- logo -->
		<div class="flex-shrink-0">
          <img class="block lg:hidden h-8 w-auto" src="/img/logos/wig32x32.svg" alt="" />
          <img class="hidden lg:block h-8 w-auto" src="/img/logos/logo-on-dark.svg" alt="" />
        </div>
		<!-- logo -->

		<!-- nav -->
		<div class="hidden sm:block sm:ml-6">
          <div class="flex">
            <NavTab href = '.'     selected='{segment === undefined}'>MTX</NavTab>
			<NavTab href = 'dai'   selected='{segment === "dai"}'>With DAI</NavTab>
			<NavTab href = 'about' selected='{segment === "about"}'>About</NavTab>
          </div>
		</div>
		<!-- nav -->
	  </div>

	  <!-- hamburger icon -->
      <div class="-mr-2 flex sm:hidden">
        <button on:click="{() => open = !open}" class="inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:bg-gray-700 focus:text-white transition duration-150 ease-in-out">
          <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
            <path class:inline-flex="{!open}" class:hidden="{open}" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            <path class:inline-flex="{open}" class:hidden="{!open}" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
	  </div>
	  <!-- hamburger icon -->
	</div>
  </div>
  <!-- default -->

  <!-- menu -->
  <div class:hidden="{!open}" class:block="{open}" class="sm:hidden">
    <div class="px-2 pt-2 pb-3">
		<NavMenuOption href = '.'     selected='{segment === undefined}' on:click="{() => open = false}">MTX</NavMenuOption>
		<NavMenuOption href = 'dai'   selected='{segment === "dai"}' on:click="{() => open = false}">With DAI</NavMenuOption>
		<NavMenuOption href = 'about' selected='{segment === "about"}' on:click="{() => open = false}">About</NavMenuOption>
    </div>
  </div>
  <!-- menu -->

</nav>
