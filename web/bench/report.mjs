// Prints every bench result beside its limit, and exits non-zero when one is exceeded or missing.
// Usage: node report.mjs <results.jsonl>, one {"key", "value", "detail"} per line.
import { existsSync, readFileSync } from 'node:fs';
import { CHECKS } from './limits.mjs';

const file = process.argv[2];
const results = new Map(
	(existsSync(file) ? readFileSync(file, 'utf8') : '')
		.split('\n')
		.filter(Boolean)
		.map((line) => JSON.parse(line))
		.map((result) => [result.key, result])
);

let failed = 0;
const rows = CHECKS.map((check) => {
	const result = results.get(check.key);
	const limit = `${check.atLeast ? '>=' : '<'} ${check.limit} ${check.unit}`;
	const measured = result ? `${result.value} ${check.unit}` : 'not measured';
	let status;
	if (check.skipEnv && process.env[check.skipEnv]) status = 'not enforced';
	else if (!result) status = 'FAIL';
	else if (check.atLeast ? result.value >= check.limit : result.value < check.limit) status = 'ok';
	else status = 'FAIL';
	if (status === 'FAIL') failed += 1;
	return [check.label, measured, limit, status, result?.detail ?? ''];
});

const header = ['Check', 'Measured', 'Limit', 'Result', 'Detail'];
const widths = header.map((title, column) =>
	Math.max(title.length, ...rows.map((row) => row[column].length))
);
const line = (cells) =>
	cells
		.map((cell, column) => cell.padEnd(widths[column]))
		.join('  ')
		.trimEnd();

console.log(`\n${line(header)}\n${line(widths.map((width) => '-'.repeat(width)))}`);
for (const row of rows) console.log(line(row));
console.log(
	failed ? `\nBench failed: ${failed} over the limit or not measured.` : '\nBench passed.'
);
process.exit(failed ? 1 : 0);
