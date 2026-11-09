---
title: Languages
---

# Languages

Mediarr speaks English, Croatian, German and Slovenian. English is the main language, and Croatian is complete. German and Slovenian are machine translated for now, and say so where you choose them, until someone who speaks them has read them.

## Choosing a language

- **Web:** in the account menu, under **Language**. Before you sign in, from the language menu on the sign-in page.
- **App:** **Settings → Language**. A phone that has never chosen one starts in its own language when Mediarr speaks it, otherwise in English.

The choice is saved to your account. A new browser or phone where you sign in starts in it. A device where you have already chosen keeps its choice, and gives it to your account. E-mails from Mediarr (a shared album, a new password, a device that stopped backing up) come in your language.

## Adding or improving a language

Each language is one file in each part. A missing text shows in English, never as its key.

| Part | File | Format |
| --- | --- | --- |
| Web | `web/src/lib/i18n/xx.json` | key → text, with `{name}` for what is filled in |
| App | `mobile/lib/l10n/app_xx.arb` | ARB, Flutter's own format |
| E-mails | `server/internal/words/words.go` | one block per language |

Texts that depend on a number use plural forms, such as `{count, plural, one {# photo} other {# photos}}`. Croatian and Slovenian have more forms than English (`few`, and in Slovenian `two`).

A new language is also added to the list of languages: `languages` in `web/src/lib/i18n.svelte.ts` and `appLanguages` in `mobile/lib/l10n/l10n.dart`. The check that runs with every change fails on a text the code uses but English does not have, and prints how much of each language is translated.
