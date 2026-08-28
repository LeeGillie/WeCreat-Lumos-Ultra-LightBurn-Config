# Outreach — what has been sent, and what is still a draft

This folder mixes **sent correspondence** with **unsent drafts**, which is confusing without an
index. This is the index. Update it when you send something.

Format conventions — which file goes to which destination, and why — are in
[`plaintext/README.md`](plaintext/README.md).

## Sent

| When | To | File | Outcome |
|---|---|---|---|
| 2026-08-26 | **WeCreat support** | [`plaintext/wecreat-support-email.txt`](plaintext/wecreat-support-email.txt) | Replied 2026-08-27. "Almost all of your findings are correct." Upload path in progress; test builds close |
| 2026-08-26 | **LightBurn forum**, WeCreat category | [`lightburn-report.md`](lightburn-report.md) | Thread live. Replies from LightBurn support, a LightBurn dev, and one owner |
| 2026-08-26 | **WeCreat owners' FB group** | [`plaintext/facebook-group-post.txt`](plaintext/facebook-group-post.txt) | First community contributor, Chris Zambesi — see [`captures/community-01-lumos-flex-chris-zambesi.md`](../captures/community-01-lumos-flex-chris-zambesi.md) |
| 2026-08-27 06:37 | **WeCreat support** | [`plaintext/wecreat-followup-2026-08-27-SENT.txt`](plaintext/wecreat-followup-2026-08-27-SENT.txt) | Five questions. **Unanswered as of writing** |
| 2026-08-27 | **LightBurn forum** | [`lightburn-forum-reply-2-2026-08-27.md`](lightburn-forum-reply-2-2026-08-27.md) | Correction post. Received well by both the dev and the owner who had pushed back |
| 2026-08-27 | **WeCreat owners' FB group** | [`plaintext/facebook-followup-2026-08-27.txt`](plaintext/facebook-followup-2026-08-27.txt) | **POSTED.** Note: the on-disk file was edited *after* posting — it now carries an eyewear-correction section and a rewritten firmware paragraph that are **not** in the live post. Treat the live post as the record, not this file. One statement in it is now known wrong: it says a developer "suspects a newer build exists"; his machine is in fact on an **older** build |
| 2026-08-28 | **WeCreat owners' FB group** | [`plaintext/facebook-delta-2026-08-28.txt`](plaintext/facebook-delta-2026-08-28.txt) | **POSTED** as a comment on the 2026-08-27 post. Carries the eyewear correction and the `000236` / `000240` regression — the latter supersedes the "suspects a newer build" line in the parent post. Asks owners for version string, fill result, speed, fill type and source |
| 2026-08-28 13:33 | **WeCreat support** | [`plaintext/wecreat-reply-2026-08-28-SENT.txt`](plaintext/wecreat-reply-2026-08-28-SENT.txt) | Reply to Allen: safety correction published, test-build confidentiality accepted, publishing terms implemented. Asks for the OD rating and certification standard |
| 2026-08-28 14:00 | **WeCreat support** | [`plaintext/wecreat-firmware-note-2026-08-28-SENT.txt`](plaintext/wecreat-firmware-note-2026-08-28-SENT.txt) | The `000236` / `000240` pair, plus: is `000236` obtainable and is downgrade supported? **Does not include the speed inversion** — that arrived 52 minutes later |

## Drafted, not sent

| To | File | Send when |
|---|---|---|
| **LightBurn forum** | [`lightburn-forum-reply-3-2026-08-27.md`](lightburn-forum-reply-3-2026-08-27.md) | After the repo is pushed — it links to `tools/analyze-gcode.ps1` |
| **WeCreat support** | [`plaintext/wecreat-followup-2-controller-findings.txt`](plaintext/wecreat-followup-2-controller-findings.txt) | Once the 06:37 exchange has run its course. It is a separate subject — controller configuration and network exposure — and should not compete with the questions already open |
| **LightBurn users' FB group** | [`plaintext/lightburn-facebook-post.txt`](plaintext/lightburn-facebook-post.txt) | Posting status unconfirmed — check before re-sending |
| **WeCreat support** | [`plaintext/wecreat-followup-3-firmware-2026-08-28.txt`](plaintext/wecreat-followup-3-firmware-2026-08-28.txt) | **After the 87,000 mm/min test has been run.** Carries the speed inversion, which is the one thing Allen has not seen. Worth sending — not worth sending as a third message in one day without a measurement in it. Has a bracketed slot for the result |

## House rules for this folder

- **Record what was actually sent, verbatim**, in a file marked `SENT`. Drafts drift after the
  fact; the record should not.
- **This index records what was *believed* sent.** On 2026-08-28 it listed the owners' group
  follow-up as unposted when it had gone up 17 hours earlier, and that error was then repeated
  back as fact. **Confirm against the live post or thread before relying on a row here** — and
  never edit a file after posting from it without recording that the two have diverged.
- **Delete superseded drafts.** A folder of near-identical unsent versions is how you end up
  sending the wrong one.
- **One thread per correspondent.** WeCreat support asked for this explicitly on 2026-08-27, and
  it is good practice regardless.
- **One subject per message, and let it be answered before opening another.** Stacking a second
  message on top of an open one splits the reply and usually gets the harder question skipped.
