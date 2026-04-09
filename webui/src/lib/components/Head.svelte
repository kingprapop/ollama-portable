<script lang="ts">
	import type { LocalizedString } from 'typesafe-i18n';

	export let title: LocalizedString | LocalizedString[] | string | string[] | undefined = undefined;
	const SEPARATOR = ' • ';
	$: formattedTitle = title
		? (Array.isArray(title) ? title.join(SEPARATOR) : title) + SEPARATOR + 'Ollama Portable'
		: 'Ollama Portable';
</script>

<svelte:head>
	<title>{formattedTitle}</title>
</svelte:head>
