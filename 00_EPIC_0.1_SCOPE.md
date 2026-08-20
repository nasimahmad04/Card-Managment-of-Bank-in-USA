# EPIC 0.1 — Core Data Model & Security Baseline
### Bank Card Management System (USA) — Oracle DB Object Build

**Source:** `02_Jira_Epics_Stories_Card_Management.md` — Phase 0, Epic 0.1 (Sprints 1-3)
**Epic Goal:** Establish the foundational Oracle schema entities and PCI-compliant security
posture before any functional module is built. Nothing customer-facing yet — everything
downstream (Phase 1 MVP onward) depends on this.

## Stories in scope & traceability

| Story ID | Title | Acceptance Criteria (from Jira) | Points | Objects delivered |
|---|---|---|---|---|
| CARD-001 | Design core entity schema (Customer, Account, Card, CardProduct) | Customer/Account/Card/CardProduct tables exist with defined PK/FK relationships and support all 3 products (debit/credit/prepaid) via a `product_type` discriminator | 8 | `CM_CUSTOMER`, `CM_ACCOUNT`, `CM_CARD_PRODUCT`, `CM_CARD` |
| CARD-002 | Implement PAN tokenization/vaulting service | Raw PAN never persists outside the PCI-scoped vault; all other tables reference a surrogate token; AES-256 encryption at rest verified | 8 | `CM_TOKEN_VAULT`, `PKG_TOKEN_VAULT` (tokenize/detokenize/mask), `FN_MASK_PAN` |
| CARD-003 | Establish PCI DSS CDE network segmentation | CDE boundary — infra/network segmentation, not a DB object. Modeled here only as a scope register so audits can trace which DB objects sit inside the CDE. | 13 | `CM_CDE_ASSET_SCOPE` (register table + seed data) |
| CARD-004 | Implement immutable audit log service | Any state change to Card/Account writes an audit record (who/what/when/before/after) to an append-only store `[FR-71]` | 5 | `CM_AUDIT_LOG`, `PKG_AUDIT_LOG`, `TRG_CM_CARD_AUDIT`, `TRG_CM_ACCOUNT_AUDIT`, `TRG_CM_AUDIT_LOG_IMMUTABLE` |
| CARD-005 | Role-based access control (RBAC) framework | PAN masked per role; access is logged `[FR-72]` | 5 | `CM_ROLE`, `CM_USER_ROLE_MAP`, `CM_DATA_ACCESS_LOG`, `PKG_RBAC_ACCESS` |
| CARD-006 | OFAC/sanctions screening service integration | Real-time match/no-match result from an OFAC list provider `[FR-02]` — Reg: BSA/OFAC | 8 | `CM_OFAC_WATCHLIST`, `CM_OFAC_SCREEN_RESULT`, `PKG_OFAC_SCREENING` |

**Epic 0.1 Total: 47 pts** (matches source doc)

## Object Naming Convention
- Tables: `CM_<ENTITY>` (CM = Card Management)
- Sequences: `SEQ_CM_<ENTITY>`
- Packages: `PKG_<AREA>` (spec `.pks` + body `.pkb`)
- Triggers: `TRG_<TABLE>_<PURPOSE>`
- Functions: `FN_<PURPOSE>`

## Design decisions worth calling out
1. **CM_CARD has no plain-text PAN column at all** — only `CARD_TOKEN_ID` (FK to the vault) and a
   cached `CARD_NUMBER_MASKED` display column. This structurally enforces CARD-002 rather than
   relying on discipline — there is nowhere in the schema outside `CM_TOKEN_VAULT` a raw PAN *can*
   go.
2. **CM_AUDIT_LOG is enforced immutable** via `TRG_CM_AUDIT_LOG_IMMUTABLE`, which blocks UPDATE and
   DELETE at the database level — not just "nobody's supposed to touch it."
3. **`product_type`** lives on `CM_CARD_PRODUCT` as a `CHECK` constraint (`DEBIT`/`CREDIT`/`PREPAID`)
   and cascades to every card issued against that product, per CARD-001's acceptance criteria.
4. **CARD-003 (CDE network segmentation)** is fundamentally an infrastructure/VLAN-VPC concern, not
   a database concern — no amount of DDL implements a network boundary. `CM_CDE_ASSET_SCOPE` is
   included so the *documentation* requirement ("documented access control list") has a queryable
   home, but the actual segmentation work happens outside the DB layer.

## Folder Structure (SQL Developer style)
```
CardManagementBankUSA/
├── 00_EPIC_0.1_SCOPE.md
├── 00_Master_Scripts/
│   └── 00_run_all.sql              -- run everything, in dependency order
├── 01_Tables/                      -- DDL: CREATE TABLE (CARD-001, 002, 003, 004, 005, 006)
├── 02_Sequences/                   -- DDL: CREATE SEQUENCE
├── 03_Constraints/                 -- PK / FK / UK / CHECK
├── 04_Indexes/                     -- CREATE INDEX
├── 05_Views/                       -- role-masked views (CARD-005)
├── 06_Packages/                    -- package spec (.pks) + body (.pkb)
├── 07_Triggers/                    -- audit + immutability triggers (CARD-004)
├── 08_Functions/                   -- FN_MASK_PAN, FN_GENERATE_TOKEN
├── 09_Procedures/                  -- standalone exception package
└── 10_QA_Test_Scripts/             -- QA scenarios mapped to each story
```
