// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		interface Error {
			/** What kind of failure, for the error page. */
			kind?: import('#lib/errors.ts').ErrorKind;
		}
		// interface Locals {}
		// interface PageData {}
		interface PageState {
			viewer?: string;
		}
		// interface Platform {}
	}
}

export {};
