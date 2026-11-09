<script lang="ts">
	import { onMount } from 'svelte';
	import { api, formatBytes, type ImportDetail, type UserImport } from '#lib/api.ts';
	import { uploadImportPart } from '#lib/importUpload.ts';
	import Bar from '#lib/design/components/Bar.svelte';
	import Button from '#lib/design/components/Button.svelte';
	import Card from '#lib/design/components/Card.svelte';
	import Icon from '#lib/design/components/Icon.svelte';
	import Skeleton from '#lib/design/components/Skeleton.svelte';
	import { showToast } from '#lib/design/components/toast.svelte.ts';

	import { lang, t, k, type Key } from '#lib/i18n.svelte.ts';

	type Source = 'takeout' | 'icloud';
	type Picked = {
		file: File;
		loaded: number;
		state: 'waiting' | 'sending' | 'in' | 'failed';
		error?: string;
	};

	let source = $state<Source>('takeout');
	let picked = $state<Picked[]>([]);
	let sending = $state(false);
	let current = $state<UserImport | undefined>();
	let imports = $state<UserImport[] | undefined>();
	let reports = $state<Record<string, ImportDetail>>({});
	let timer: ReturnType<typeof setInterval> | undefined;

	const STATUS: Record<UserImport['status'], { label: Key; tone: string }> = {
		uploading: { label: k('account.import.waitingForFiles'), tone: '' },
		running: { label: k('account.import.running'), tone: 'run' },
		done: { label: k('qRSignInDialog.done'), tone: 'ok' },
		failed: { label: k('admin.jobs.failed'), tone: 'err' },
		cancelled: { label: k('account.import.stopped'), tone: '' }
	};
	const SOURCE: Record<Source, string> = { takeout: 'Google Takeout', icloud: 'iCloud' };

	const allIn = $derived(picked.length > 0 && picked.every((p) => p.state === 'in'));
	const totalBytes = $derived(picked.reduce((sum, p) => sum + p.file.size, 0));
	const sentBytes = $derived(picked.reduce((sum, p) => sum + p.loaded, 0));

	async function load() {
		imports = await api.myImports().catch(() => imports ?? []);
		const busy = imports.some((entry) => entry.status === 'running');
		clearInterval(timer);
		// Progress is asked for only while something runs.
		if (busy) timer = setInterval(load, 3000);
	}

	onMount(() => {
		load();
		return () => clearInterval(timer);
	});

	function choose(event: Event) {
		const input = event.currentTarget as HTMLInputElement;
		const files = [...(input.files ?? [])].filter(
			(file) => !picked.some((p) => same(p.file, file))
		);
		picked = [...picked, ...files.map((file) => ({ file, loaded: 0, state: 'waiting' as const }))];
		input.value = '';
	}

	function same(a: File, b: File) {
		return a.name === b.name && a.size === b.size && a.lastModified === b.lastModified;
	}

	function drop(index: number) {
		picked = picked.filter((_, i) => i !== index);
	}

	function update(index: number, changes: Partial<Picked>) {
		picked = picked.map((p, i) => (i === index ? { ...p, ...changes } : p));
	}

	/** One file at a time, so the first ones are complete early and a drop loses the least. */
	async function send() {
		sending = true;
		try {
			current ??= await api.createMyImport(source);
			for (let index = 0; index < picked.length; index++) {
				if (picked[index].state === 'in') continue;
				update(index, { state: 'sending', error: undefined });
				try {
					await uploadImportPart(current.id, picked[index].file, (loaded) =>
						update(index, { loaded })
					).done;
					update(index, { state: 'in', loaded: picked[index].file.size });
				} catch (cause) {
					update(index, { state: 'failed', error: (cause as Error).message });
				}
			}
		} catch (cause) {
			showToast('err', (cause as Error).message);
		} finally {
			sending = false;
			load();
		}
	}

	async function bringIn(id: string) {
		try {
			await api.runImport(id);
			if (current?.id === id) {
				current = undefined;
				picked = [];
			}
			showToast('ok', t('account.import.theImportHasStarted'));
		} catch (cause) {
			showToast('err', (cause as Error).message);
		}
		load();
	}

	async function act(work: () => Promise<void>) {
		try {
			await work();
		} catch (cause) {
			showToast('err', (cause as Error).message);
		}
		load();
	}

	async function toggleReport(id: string) {
		if (reports[id]) {
			reports = Object.fromEntries(Object.entries(reports).filter(([key]) => key !== id));
			return;
		}
		reports = { ...reports, [id]: await api.importDetail(id) };
	}

	const done = (entry: UserImport) => entry.added + entry.skipped + entry.failed;
	const pct = (entry: UserImport) => (entry.total ? (done(entry) / entry.total) * 100 : 0);
	const when = (value: string) =>
		new Date(value).toLocaleString(lang(), { dateStyle: 'medium', timeStyle: 'short' });
</script>

<svelte:head><title>{t('common.import')} — Mediarr</title></svelte:head>

<div class="ph">
	<div>
		<h1>{t('common.import')}</h1>
		<p>
			{t('account.import.bringYourPhotosInFrom')}
		</p>
	</div>
</div>

<div class="imp">
	<Card id="new" title={t('account.import.newImport')}>
		<fieldset class="imp-source" disabled={Boolean(current)}>
			<legend class="sr">{t('account.import.fromWhere')}</legend>
			{#each ['takeout', 'icloud'] as const as option (option)}
				<label class="imp-option" class:on={source === option}>
					<input type="radio" name="source" value={option} bind:group={source} />
					<b>{SOURCE[option]}</b>
					<small>
						{#if option === 'takeout'}
							{t('account.import.atTakeoutGoogleComChoose')}
						{:else}
							{t('account.import.atPrivacyAppleComAsk')}
						{/if}
					</small>
				</label>
			{/each}
		</fieldset>

		<label class="imp-drop">
			<input
				type="file"
				accept=".zip,application/zip"
				multiple
				onchange={choose}
				disabled={sending}
			/>
			<Icon name="upload" size={22} />
			<span>
				<b>{t('account.import.chooseAllTheZipFiles')}</b>
				<small>{t('account.import.asYouDownloadedThemWithout')}</small>
			</span>
		</label>

		{#if picked.length}
			<ul class="set-list imp-parts" aria-label={t('account.import.chosenFiles')}>
				{#each picked as part, index (part.file.name + part.file.size)}
					<li data-part={part.state}>
						<span class="set-list-t">
							<b class="mono">{part.file.name}</b>
							<small>
								{formatBytes(part.file.size)}
								{#if part.state === 'in'}
									· <em class="set-chip ok">{t('account.import.uploaded')}</em>
								{:else if part.state === 'failed'}
									· <em class="set-chip err">{t('account.import.failed')}</em> {part.error}
								{/if}
							</small>
							{#if part.state === 'sending'}
								<Bar pct={(part.loaded / part.file.size) * 100} progress />
							{/if}
						</span>
						{#if part.state !== 'in' && !sending}
							<Button small onclick={() => drop(index)}>{t('common.remove2')}</Button>
						{/if}
					</li>
				{/each}
			</ul>
			<div class="set-foot imp-foot">
				<span class="imp-sum">{formatBytes(sentBytes)} / {formatBytes(totalBytes)}</span>
				{#if allIn && current}
					<Button variant="gold" small onclick={() => bringIn(current!.id)}
						>{t('account.import.bringIn')}</Button
					>
				{:else}
					<Button variant="gold" small disabled={sending} onclick={send}
						>{sending ? t('account.import.uploading') : t('account.import.upload')}</Button
					>
				{/if}
			</div>
		{/if}
	</Card>

	<Card id="imports" title={t('account.import.yourImports')}>
		{#if imports === undefined}
			<Skeleton height="56px" />
		{:else if imports.length === 0}
			<p class="alb-meta">
				{t('account.import.youHaveNotImportedAnything')}
			</p>
		{:else}
			<ul class="set-list" aria-label={t('account.import.yourImports')}>
				{#each imports as entry (entry.id)}
					<li data-import={entry.status}>
						<span class="set-list-t">
							<b>{SOURCE[entry.source as Source] ?? entry.source} · {when(entry.createdAt)}</b>
							<small>
								<em class="set-chip {STATUS[entry.status].tone}">{t(STATUS[entry.status].label)}</em
								>
								{#if entry.status === 'uploading'}
									{entry.parts.length}
									{t('account.import.zipFilesUploaded')}
								{:else}
									{t('account.import.added')}
									{entry.added} · {t('account.import.alreadyHereOrDeleted')}
									{entry.skipped} · {t('account.import.failed2')}
									{entry.failed}{#if entry.total}
										· {done(entry)} / {entry.total}{/if}
								{/if}
							</small>
							{#if entry.status === 'running' && entry.total}
								<Bar pct={pct(entry)} progress />
							{/if}
							{#if reports[entry.id]}
								<div class="imp-report">
									{#if reports[entry.id].problems.length === 0}
										<p>{t('account.import.everythingCameIn')}</p>
									{:else}
										<ul>
											{#each reports[entry.id].problems as problem, n (n)}
												<li><b class="mono">{problem.name}</b> {problem.reason}</li>
											{/each}
										</ul>
									{/if}
								</div>
							{/if}
						</span>
						<span class="imp-acts">
							{#if entry.status === 'uploading' && entry.parts.length}
								<Button variant="gold" small onclick={() => bringIn(entry.id)}
									>{t('account.import.bringIn')}</Button
								>
							{/if}
							{#if entry.status === 'running'}
								<Button small onclick={() => act(() => api.stopImport(entry.id))}
									>{t('common.stop')}</Button
								>
							{/if}
							{#if entry.fromZip && (entry.status === 'cancelled' || entry.status === 'failed') && entry.parts.length}
								<Button small onclick={() => bringIn(entry.id)}
									>{t('account.import.continue')}</Button
								>
							{/if}
							{#if entry.failed > 0}
								<Button small onclick={() => toggleReport(entry.id)}
									>{reports[entry.id] ? t('common.hide') : t('account.import.report')}</Button
								>
							{/if}
							{#if entry.status !== 'running'}
								<Button small variant="danger" onclick={() => act(() => api.removeImport(entry.id))}
									>{t('common.remove')}</Button
								>
							{/if}
						</span>
					</li>
				{/each}
			</ul>
			<p class="alb-meta">
				{t('account.import.removingAnImportDeletesIts')}
			</p>
		{/if}
	</Card>
</div>
