# ScanFair Privacy Data Flow and DPIA Decision Path

Status: accepted for local development

Last reviewed: 2026-08-11

Owner: Mustafa Demir

This document describes the current iOS MVP. Planned components are shown as
disabled boundaries and must not be interpreted as active processing. The
machine-readable source of truth is
[`privacy-data-inventory.yaml`](privacy-data-inventory.yaml).

## Current Data Flow

```mermaid
flowchart LR
  U["Device user"] -->|camera permission or manual EAN| A["ScanFair iOS app"]
  C["Camera frames"] -->|on-device detection only| A
  A -->|HTTPS: barcode, request metadata| O["Open Food Facts"]
  O -->|public product response| A
  A -->|in-memory mapping and score calculation| R["Result and details"]
  A -->|maximum 10 product objects| M["Volatile runtime memory"]
  M -->|app process ends| D["Automatic deletion"]

  A -. prohibited .-> B["ScanFair remote backend"]
  A -. prohibited .-> T["Analytics or tracking"]
  C -. prohibited .-> O
```

Current guarantees:

- Camera images are neither returned by the scanner nor persisted or uploaded.
- The decoded barcode is sent directly to Open Food Facts only after a user
  scan or manual lookup.
- ScanFair adds no account, advertising or device identifier to the request.
- Network infrastructure and Open Food Facts can nevertheless process network
  metadata such as the IP address; provider roles, region and retention still
  require qualified review before external beta.
- Product objects are limited to ten entries in volatile app memory. There is
  no ScanFair cloud history, account, analytics, tracking or location feature.

## Planned Remote Boundary

```mermaid
flowchart LR
  A["ScanFair iOS app"] -->|read-only product request| API["Authenticated public API"]
  API --> C["Source-partitioned product cache"]
  W["Trusted server writer"] --> C
  W --> E["External ESG sources"]
  API --> L["Security and access logs"]

  S["Service role"] --> W
  S -. prohibited .-> A
  C -. raw restricted source data prohibited .-> A
```

This path remains disabled until NEXT-04 defines its threat model and NEXT-05
meets the license, privacy, security, retention, rights and processor evidence
contracts. Enabling a remote backend changes the applicable gate profile.

## DPIA Decision Path

```mermaid
flowchart TD
  N["New beta, backend, account, analytics or data-source change"] --> I["Update data inventory and actual data-flow evidence"]
  I --> C["Assess EDPB high-risk criteria and national authority guidance"]
  C --> H{"Processing likely to create high risk?"}
  H -->|yes or unresolved| P["Perform and approve DPIA before activation"]
  H -->|no| R["Record approved screening rationale and evidence hashes"]
  P --> G["G-PRIVACY-BOUNDARY strict profile"]
  R --> G
  G -->|pass| A["Feature may proceed to the next release decision"]
  G -->|fail| B["Activation remains blocked"]
```

The current local-only preliminary view is `DPIA not required`, because there
is no persistent user profile, special-category data request, location
tracking, large-scale monitoring or decision about a person. This is not a
legal approval. External beta and every remote feature require a documented,
qualified DPIA screening. Uncertainty is treated as a blocker, not as a waiver.

## Change Triggers

Re-run the inventory, DPIA screening and App Privacy classification whenever a
change introduces or modifies:

- off-device retention, a backend, user account or scan history;
- analytics, diagnostics, tracking, advertising or location;
- a new SDK, processor, subprocessor, region or international transfer;
- a new purpose, data type, recipient, retention period or user-rights path;
- matching of product interactions with an identifiable person;
- children or other vulnerable data subjects.

Primary controls: GDPR Articles 5, 6, 13, 25, 28, 30, 32 and 35; EDPB DPIA
Guidelines WP248 rev.01; BfDI DPIA guidance; Apple App Privacy Details and App
Review Guidelines.
