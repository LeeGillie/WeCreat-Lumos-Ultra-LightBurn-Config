# Which format to send where

The Markdown drafts in the parent folder are for reading. **Do not paste rendered Markdown into an
email client** — the preview's colours travel with it, which is how you end up with light-grey text
on a white background and unreadable code blocks.

| Destination | Send | Why |
|---|---|---|
| **WeCreat support** | [`wecreat-support-email.txt`](wecreat-support-email.txt) | Plain text. Always renders, never has a contrast problem, and support ticket systems handle it cleanly |
| **LightBurn forum** | [`../lightburn-report.md`](../lightburn-report.md) — **paste the raw Markdown** | The LightBurn forum runs Discourse, which renders Markdown natively. Paste the *source*, not a preview |
| **Facebook group** | [`facebook-group-post.txt`](facebook-group-post.txt) | Facebook strips formatting anyway |

## Why plain text is the right call for the support email

It is not a compromise. For a technical bug report it is better:

- **No rendering risk.** No theme, no inherited colours, no code blocks that arrive black-on-black
- **Quoting works.** A support agent replying inline gets clean quoted text
- **It survives forwarding.** This needs to reach an engineer, probably through two or three hands
- **Ticket systems index it properly**

Console output and G-code are indented four spaces rather than fenced. That reads correctly
everywhere and needs no styling at all.

## If you do want formatting somewhere

Compose in Thunderbird's own editor and apply formatting there, rather than pasting styled content
in from outside. Anything pasted carries the source document's CSS with it — that is the whole
cause of the grey-on-white problem.
