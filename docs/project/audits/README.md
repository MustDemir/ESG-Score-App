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
| 2026-08-10 | [Product Engineering Gap Analysis](2026-08-10-product-engineering-gap-analysis.md) | Twelve disciplines from product discovery through scientific, legal, operational and App Store readiness |
| 2026-08-11 | [Data-License Composition Assessment](2026-08-11-data-license-composition-assessment.md) | OFF/ODbL classification, source separation, gate profiles and remote activation blockers |
| 2026-08-11 | [Claims and Privacy Boundary Assessment](2026-08-11-claims-privacy-boundaries-assessment.md) | Claim inventory, neutral nutrition boundary, privacy data flow, DPIA path and activation gates |
| 2026-08-11 | [Backend Threat Model Assessment](2026-08-11-backend-threat-model-assessment.md) | STRIDE/OWASP API threats, trusted-writer contract and fail-closed EU-Supabase activation |
| 2026-08-12 | [EU Supabase Local Integration Assessment](2026-08-12-eu-supabase-local-integration-assessment.md) | Local Edge writer, server-only RPCs, RLS, cache fallback and real wrapper integration |
| 2026-08-12 | [Provider Governance Gates Assessment](2026-08-12-provider-governance-gates-assessment.md) | Gate schema, DPA, subprocessors, Free Plan cost controls and fail-closed remote activation |
| 2026-08-17 | [Remote Schema State Assessment](2026-08-17-remote-schema-state-assessment.md) | Linked migration reconciliation, schema drift, remote data state and activation boundary |
| 2026-08-18 | [Remote Deployment Verification](2026-08-18-remote-deployment-verification.md) | Migration-10 remote behavior, hosted pgTAP limitation and service-role least-privilege finding |
| 2026-08-18 | [Retention and Cleanup Assessment](2026-08-18-retention-cleanup-assessment.md) | Bounded technical retention, durable replay watermarks, pg_cron scheduling and activation boundary |
| 2026-09-04 | [Retention-Observability Remote Verification](2026-09-04-retention-observability-remote-verification.md) | Migration 13, real health-monitor history and rollback-clean failure/recovery lifecycle verification |
| 2026-09-04 | [Control-Assurance-Review der Quality Gates](2026-09-04-control-assurance-review.md) | Frist-Erzwingung, Quellen-Deltas, Feature-Deklarationen und Negativtests |
| 2026-09-06 | [Public-Read Abuse Protection Validation](2026-09-06-public-read-abuse-protection-validation.md) | Rollback-only migration validation, pre-request limiter behavior and no-persistence confirmation |
| 2026-09-11 | [Ticket Workflow Control Validation](2026-09-11-ticket-workflow-control-validation.md) | Child-Ticket-Schema, DoR/DoD, Abhaengigkeiten, Gate-Mapping, Negativtests und PR-Bindung |
| 2026-09-22 | [Agent- und Kontrollreview](2026-09-22-agent-control-review.md) | Ticket-/CI-Nacharbeit, PostgREST-Integrationsluecken und Cache-Frischegrenzen |
| 2026-09-23 | [Public-Read HTTP Validation](2026-09-23-public-read-http-validation.md) | Migration 15, echte Gateway-Quoten und erfolgreicher Edge-/Datenbank-Rundlauf in isolierter Instanz |
| 2026-09-23 | [Backend-Abschlussreview](2026-09-23-backend-abschlussreview.md) | Separater technischer Pruefdurchgang, erneute Laufzeittests und explizite Hosted-/Privacy-Grenzen |
| 2026-09-23 | [Cache-Frische Validation](2026-09-23-cache-frische-validation.md) | AR-07/08, negative Metadaten, deterministische Ablaufgrenzen und technischer Nachreview |
| 2026-09-24 | [Privacy-Review-Paket TKT-037-01](2026-09-24-privacy-review-package.md) | PRV-008-Inventar, scoped Privacy-/DPIA-Freigaben, fail-open DPIA-Entscheidung behoben und Hash-Reihenfolge |
