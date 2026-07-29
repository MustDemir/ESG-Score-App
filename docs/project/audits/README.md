# Project Audits

This directory stores dated, reviewable audit reports. Audit reports preserve
the reviewed scope and evidence at the time of the audit. Remediation status is
tracked separately in `backlog.yaml`, `improvement-register.yaml` and
`progress.yaml`.

## Minimum Content

Each report records:

- audit date and normalization date
- reviewed commit or branch
- scope and explicit exclusions
- method and evidence
- finding identifier, severity and disposition
- linked backlog task, requirement, gate or ADR
- verification evidence for resolved findings

Corrections do not silently erase the original observation. The report explains
what was inaccurate and records the corrected assessment.

## Reports

| Date | Report | Scope |
|---|---|---|
| 2026-07-28 | [Code quality, accessibility and CI audit](2026-07-28-code-quality-accessibility-ci-audit.md) | Scoring, result UI, supply-chain CI and documentation consistency |
