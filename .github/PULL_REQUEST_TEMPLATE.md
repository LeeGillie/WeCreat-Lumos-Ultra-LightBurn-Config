## What this changes

<!-- One or two sentences. -->

## Type

- [ ] Documentation
- [ ] Profile / profile spec
- [ ] Tooling
- [ ] Capture (hardware findings)
- [ ] Other

## Evidence

<!--
If this changes a factual claim, cite the source and state the grade:
CONFIRMED-vendor / CONFIRMED-community / INFERRED / UNKNOWN.
New sources belong in docs/evidence/sources.md.
-->

## Checklist

- [ ] Claims are graded, and nothing was upgraded to a stronger grade than the evidence supports
- [ ] New sources added to `docs/evidence/sources.md`
- [ ] If a profile changed: I edited `tools/profile-spec.json` and regenerated, rather than hand-editing `profiles/draft/*.lbdev`
- [ ] `tools/validate-lbdev.ps1` passes
- [ ] No vendor material committed — no WeCreat `.lbdev`, firmware, or extracted MakeIt content, and nothing from `reference/`
- [ ] No unverified M-codes in any profile's start/end G-code or macros
- [ ] Status changes in `docs/02-feature-inventory.md` are backed by a capture or a source

## Tested on hardware?

- [ ] Yes — machine configuration below
- [ ] No — this is documentation, tooling, or a proposal

<!-- If yes:
- Sources fitted:
- Lens installed:
- Accessories fitted:
- MakeIt version:
- LightBurn version:
- Firmware banner:
-->
