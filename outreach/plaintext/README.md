# Which format to send where

The Markdown drafts in the parent folder are for reading. **Do not paste rendered Markdown into an
email client** — the preview's colours travel with it, which is how you end up with light-grey text
on a white background and unreadable code blocks.

| Destination | Send | Why |
|---|---|---|
| **WeCreat support** | [`wecreat-support-email.txt`](wecreat-support-email.txt) | Plain text. Always renders, never has a contrast problem, and support ticket systems handle it cleanly |
| **LightBurn forum** | [`../lightburn-report.md`](../lightburn-report.md) — **paste the raw Markdown** | The LightBurn forum runs Discourse, which renders Markdown natively. Paste the *source*, not a preview |
| **WeCreat owners' FB group** | [`facebook-group-post.txt`](facebook-group-post.txt) | Facebook strips formatting anyway |
| **LightBurn users' FB group** | [`lightburn-facebook-post.txt`](lightburn-facebook-post.txt) | Different audience, different angle — see below |

## The two Facebook posts are not the same post

They share a subject and almost nothing else.

**WeCreat owners** care that their machine is about to mis-scale a job, that Frame can fire the
beam, and which goggles to wear. It leads with safety and asks for help testing other WeCreat
models.

**LightBurn users** mostly do not own this machine and never will. What is useful to *them* is the
`G91` finding — that LightBurn sends fills as relative moves, with only two absolute re-anchors in
a 9,600-move job. That is transferable knowledge for anyone running a marginal serial link on any
controller, and most people have never seen it measured.

So that post leads with a question they can actually answer — *can LightBurn be made to emit fills
in absolute coordinates?* — and treats the WeCreat machine as the context rather than the subject.
Asking a group a question they can help with gets replies; announcing a repo does not.

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
