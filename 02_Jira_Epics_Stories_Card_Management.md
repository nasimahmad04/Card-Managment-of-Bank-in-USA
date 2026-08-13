# Jira Epics & Stories — Bank Card Management System
**Organized by Development Phase | Version 1.0 | August 14, 2026**
**Source:** Traces back to FR-01–FR-83 in `01_Functional_Requirements_Card_Management.md`
**Scope:** Debit + Credit + Prepaid | Consumer + Business | Issuance-model-agnostic

**Story point scale:** Fibonacci (1, 2, 3, 5, 8, 13) — relative complexity, not hours.
**Legend:** `[FR-xx]` = source requirement | `Reg:` = compliance driver

---

## Phasing Overview

| Phase | Theme | Goal |
|---|---|---|
| **Phase 0** | Platform Foundations | Data model scaffolding, security/PCI baseline, compliance plumbing — nothing customer-facing yet |
| **Phase 1 (MVP)** | Core Card Lifecycle | Applicant → issued → activated → can transact (real-time auth) → basic self-service controls. This is the walking skeleton. |
| **Phase 2** | Transaction Lifecycle & Protection | Clearing/settlement, disputes/chargebacks, fraud detection, notifications |
| **Phase 3** | Credit & Billing | Statements, interest, payments, credit bureau reporting, delinquency (credit-card-specific) |
| **Phase 4** | Advanced Channels & Growth | Digital wallets/tokenization, rewards, business/commercial cards |
| **Phase 5** | Compliance Operations & Scale | SAR/CTR, audit reporting, escheatment, DR/scale hardening |

---

## PHASE 0 — Platform Foundations

### EPIC 0.1: Core Data Model & Security Baseline
*Goal: Establish the foundational Oracle schema entities and PCI-compliant security posture before any functional module is built.*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-001 | Design core entity schema (Customer, Account, Card, CardProduct) | Given the data domain list, when schema is reviewed, then Customer/Account/Card/CardProduct tables exist with defined PK/FK relationships and support all 3 products (debit/credit/prepaid) via a `product_type` discriminator | 8 |
| CARD-002 | Implement PAN tokenization/vaulting service | Given a PAN is generated, when stored, then raw PAN never persists outside the PCI-scoped vault; all other tables reference a surrogate token; AES-256 encryption at rest verified | 8 |
| CARD-003 | Establish PCI DSS CDE network segmentation | Given the CDE boundary diagram, when infra is provisioned, then card-data-touching services are isolated in a segmented VLAN/VPC with documented access control list | 13 |
| CARD-004 | Implement immutable audit log service | Given any state change to Card/Account, when the change commits, then an audit record (who/what/when/before/after) is written to an append-only store `[FR-71]` | 5 |
| CARD-005 | Role-based access control (RBAC) framework | Given a user role (Agent, Analyst, Admin, Compliance), when they access cardholder data, then PAN is masked per role and access is logged `[FR-72]` | 5 |
| CARD-006 | OFAC/sanctions screening service integration | Given an applicant or transaction party, when screened, then a real-time match/no-match result returns from an OFAC list provider `[FR-02]` — *Reg: BSA/OFAC* | 8 |

**Epic 0.1 Total: 47 pts**

### EPIC 0.2: Issuance-Model Abstraction Layer
*Goal: Build the service interface so the system can plug into in-house issuing OR a processor/BIN sponsor without rework `[FR-74–FR-77]`.*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-007 | Define abstracted Issuing Service interface (API contract) | Given the interface spec, when either an in-house engine or processor adapter implements it, then issuance/auth/lifecycle calls behave identically to downstream consumers `[FR-74]` | 8 |
| CARD-008 | Build processor webhook ingestion adapter (stub) | Given a processor sends an auth/clearing/dispute webhook, when received, then it's normalized into internal event schema `[FR-75]` | 5 |
| CARD-009 | Build ISO 8583 message handler (in-house path) | Given an ISO 8583 auth request, when parsed, then fields map to internal Authorization entity `[FR-76]` | 13 |

**Epic 0.2 Total: 26 pts**

---

## PHASE 1 (MVP) — Core Card Lifecycle

### EPIC 1.1: Application & Origination
*`[FR-01–FR-07]` — Reg: BSA/KYC, FCRA, ECOA, CARD Act*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-010 | Capture applicant PII & run CIP/KYC | Given applicant submits application, when CIP check runs, then identity is verified or flagged for manual review within SLA `[FR-01]` | 5 |
| CARD-011 | OFAC screening at application | Given applicant data, when submitted, then OFAC check (CARD-006) runs before any approval decision `[FR-02]` | 3 |
| CARD-012 | Credit bureau pull & ability-to-pay check (credit product) | Given a credit card application, when bureau pull completes, then income/debt ratio check runs per CARD Act policy `[FR-03]` | 8 |
| CARD-013 | Adverse action notice generation | Given an application is denied, when decision is finalized, then an adverse-action letter is generated within the regulatory window `[FR-04]` — *Reg: FCRA/ECOA* | 5 |
| CARD-014 | E-sign card agreement & disclosures | Given approval, when applicant signs, then card agreement, privacy notice, and (if prepaid) short-form fee disclosure are captured with timestamp `[FR-06]` | 5 |
| CARD-015 | Product eligibility rules engine | Given applicant profile, when evaluated, then eligible products (debit/secured credit/unsecured credit/GPR prepaid) are returned `[FR-05]` | 5 |

**Epic 1.1 Total: 31 pts**

### EPIC 1.2: Card Issuance & Personalization
*`[FR-08–FR-13]` — Reg: PCI DSS, EMVCo*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-016 | PAN/CVV/expiry generation service | Given approved application, when card is created, then a PAN is generated within assigned BIN range, non-sequential, PCI-compliant `[FR-08]` | 8 |
| CARD-017 | EMV chip personalization file export | Given a physical card order, when generated, then a personalization file is sent to the card manufacturer per EMV spec `[FR-09]` | 8 |
| CARD-018 | Virtual card instant issuance | Given approval, when processed, then a virtual card (PAN/CVV/exp) is available in the mobile app within seconds, before physical card ships `[FR-13]` | 5 |
| CARD-019 | PIN generation & secure delivery | Given a new card, when PIN is set, then only a PIN block/PVV is stored (never clear-text/reversible PIN); delivery via mailer/IVR/app `[FR-11]` | 8 |
| CARD-020 | Card art selection | Given product supports multiple designs, when applicant selects, then chosen design is passed to personalization file `[FR-10]` | 2 |
| CARD-021 | Auto-reissue before expiration | Given a card nears expiry (60-90 days), when the reissue job runs, then a replacement card is generated automatically `[FR-12]` | 5 |

**Epic 1.2 Total: 36 pts**

### EPIC 1.3: Card Activation
*`[FR-14–FR-16]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-022 | Multi-channel activation (app/web/IVR) | Given a cardholder has an unactivated card, when they complete identity verification (last-4 SSN/DOB/OTP), then card status moves to Active `[FR-14]` | 5 |
| CARD-023 | Block authorization on inactive cards | Given an auth request for an unactivated card, when evaluated, then it is declined with reason "card not activated" `[FR-15]` | 3 |
| CARD-024 | Activation audit logging | Given any activation event, when it occurs, then channel/timestamp/device/IP is logged for fraud analytics `[FR-16]` | 2 |

**Epic 1.3 Total: 10 pts**

### EPIC 1.4: Real-Time Authorization Engine
*`[FR-17–FR-25]` — Reg: EMVCo, Network Rules, Reg II (Durbin)*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-025 | ISO 8583 real-time auth processing | Given an inbound auth request, when processed, then a response is returned in <300ms P99 `[FR-17]` | 13 |
| CARD-026 | Authorization validation rule chain | Given an auth request, when evaluated, then checks run in order: card status → balance/limit → velocity → MCC restriction → geo restriction → cardholder controls → fraud score → EMV cryptogram `[FR-18]` | 13 |
| CARD-027 | Partial authorization support (prepaid/debit) | Given available balance < requested amount, when eligible per network rules, then a partial approval is returned `[FR-19]` | 5 |
| CARD-028 | Authorization hold management | Given an approved auth, when posted, then a hold is placed on available balance and auto-expires per network rule if unmatched `[FR-20]` | 8 |
| CARD-029 | Authorization reversal handling | Given a reversal message (full/partial), when received, then the corresponding hold is adjusted/released `[FR-21]` | 5 |
| CARD-030 | CNP transaction validation (CVV2/AVS/3DS2) | Given a card-not-present auth, when processed, then CVV2/AVS checks run and 3DS2 step-up triggers per risk rules `[FR-23]` | 8 |
| CARD-031 | Decline reason code mapping | Given a decline decision, when returned, then it maps to the correct network response code and internal reason `[FR-25]` | 3 |
| CARD-032 | Account updater service integration | Given a card is reissued, when merchant has card-on-file, then updated card data is pushed via Visa Account Updater/MDES equivalent `[FR-24]` | 8 |

**Epic 1.4 Total: 63 pts**

### EPIC 1.5: Basic Card Controls & Status Management
*`[FR-26–FR-31], [FR-52]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-033 | Card lock/unlock self-service | Given cardholder taps "lock" in app, when confirmed, then subsequent auth requests decline within seconds `[FR-26]` | 5 |
| CARD-034 | Card lifecycle status state machine | Given any status transition request, when evaluated, then only valid transitions (Pending→Issued→Active→Suspended→Lost/Stolen→Closed→Expired) are permitted, with audit log `[FR-52]` | 8 |
| CARD-035 | Lost/stolen reporting & instant block | Given cardholder reports lost/stolen, when submitted, then card is blocked immediately and reissuance workflow triggers `[FR-31]` | 5 |
| CARD-036 | Basic spend controls (MCC/txn-type block) | Given cardholder sets a control (e.g., block gambling), when set, then the auth rule chain (CARD-026) respects it in real time `[FR-27]` | 8 |
| CARD-037 | Real-time transaction alerts | Given a transaction posts/declines, when it occurs, then a push/SMS/email alert is sent per configured preference `[FR-30]` | 5 |

**Epic 1.5 Total: 31 pts**

**PHASE 1 (MVP) TOTAL: 171 pts**

---

## PHASE 2 — Transaction Lifecycle & Protection

### EPIC 2.1: Clearing, Settlement & Fees
*`[FR-36–FR-40]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-038 | Clearing file ingestion & auth matching | Given a T+1/T+2 clearing file, when processed, then matched authorizations convert holds to posted transactions `[FR-36]` | 8 |
| CARD-039 | Unmatched clearing / force-post handling | Given a clearing record has no matching auth, when processed, then it force-posts with an exception flag for review `[FR-37]` | 5 |
| CARD-040 | Multi-currency FX transaction handling | Given a foreign-currency transaction, when posted, then FX conversion and foreign transaction fee apply per disclosed rate `[FR-39]` — *Reg: Reg Z/E disclosure* | 8 |
| CARD-041 | Fee posting engine | Given a fee-triggering event, when evaluated, then correct fee posts per disclosed schedule, respecting CARD Act penalty fee caps `[FR-40]` | 5 |

**Epic 2.1 Total: 26 pts**

### EPIC 2.2: Disputes & Chargebacks
*`[FR-41–FR-46]` — Reg: Reg E, Reg Z, Network Rules*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-042 | Dispute case creation (app/call center) | Given a cardholder disputes a transaction, when submitted, then a case is created with reason code and linked transaction `[FR-41]` | 5 |
| CARD-043 | Reg E timeline engine (debit/prepaid) | Given a debit dispute, when opened, then system enforces provisional credit by day 10 (day 20 new accounts) and resolution by day 45/90, with automated SLA alerts `[FR-42]` — *Reg: Reg E* | 13 |
| CARD-044 | Reg Z billing error engine (credit) | Given a credit dispute filed within 60 days, when opened, then resolution SLA of 2 billing cycles (max 90 days) is tracked; minimum payment excludes disputed amount `[FR-43]` — *Reg: Reg Z* | 13 |
| CARD-045 | Network chargeback generation | Given a qualifying dispute, when escalated, then a chargeback is filed with correct network-specific reason code `[FR-44]` | 8 |
| CARD-046 | Representment cycle tracking | Given a merchant re-presents, when received, then case status updates and cardholder/analyst notified with new SLA clock `[FR-45]` | 8 |
| CARD-047 | Dispute-pattern SAR trigger | Given dispute patterns match fraud-ring indicators, when detected, then a SAR case is auto-created for compliance review `[FR-46]` — *Reg: BSA* | 8 |

**Epic 2.2 Total: 55 pts**

### EPIC 2.3: Fraud & Risk Management
*`[FR-47–FR-51]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-048 | Real-time fraud scoring engine integration | Given an authorization request, when evaluated, then a fraud score (rules + ML) returns and feeds the auth rule chain `[FR-47]` | 13 |
| CARD-049 | Step-up authentication on risk score | Given a transaction scores above threshold, when flagged, then OTP/3DS challenge is triggered `[FR-48]` | 8 |
| CARD-050 | Fraud analyst case management console | Given a flagged transaction, when an analyst reviews, then they can release/block/escalate with full context `[FR-49]` | 8 |
| CARD-051 | Auto-block on confirmed fraud + reissue | Given confirmed fraud on a card, when marked, then card auto-blocks and a replacement with new PAN is triggered `[FR-50]` | 5 |
| CARD-052 | Negative file / watchlist service | Given a known-fraud PAN/device/merchant, when matched during auth, then transaction is auto-declined or scored higher `[FR-51]` | 5 |

**Epic 2.3 Total: 39 pts**

### EPIC 2.4: Servicing Enhancements
*`[FR-53–FR-56]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-053 | Card replacement workflow (damaged/compromised) | Given a replacement request, when submitted, then new card issues with option to retain/change PAN and expedite shipping `[FR-53]` | 5 |
| CARD-054 | PIN reset/change (ATM/IVR/app) | Given a PIN reset request, when identity verified, then new PIN block is stored, old invalidated `[FR-54]` | 5 |
| CARD-055 | Card closure workflow | Given a closure request, when processed, then pending auths settle, future auths block, final balance handled (refund/payoff) `[FR-55]` | 8 |
| CARD-056 | Credit limit management | Given a limit change request, when approved per policy, then new limit applies to real-time auth engine immediately `[FR-56]` | 5 |

**Epic 2.4 Total: 23 pts**

**PHASE 2 TOTAL: 143 pts**

---

## PHASE 3 — Credit & Billing (Credit-Card-Specific)

### EPIC 3.1: Statements & Interest
*`[FR-58–FR-59]` — Reg: Reg Z, CARD Act*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-057 | Monthly billing statement generation | Given a billing cycle closes, when statement generates, then it includes min. payment, APR, due date, grace period per Reg Z content rules `[FR-58]` | 8 |
| CARD-058 | Average daily balance interest calculation | Given a billing cycle, when interest is calculated, then average daily balance method is applied and disclosed correctly `[FR-59]` | 8 |
| CARD-059 | CARD Act payment allocation engine | Given a payment above minimum, when allocated, then it applies to highest-APR balance segment first `[FR-59]` — *Reg: CARD Act* | 8 |

**Epic 3.1 Total: 24 pts**

### EPIC 3.2: Payments & Delinquency
*`[FR-60–FR-62]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-060 | Payment processing (ACH/check/wire) + autopay | Given a payment is submitted, when processed, then it posts same-day per Reg Z and autopay recurs correctly `[FR-60]` | 8 |
| CARD-061 | Delinquency & penalty APR engine | Given an account goes past due, when the delinquency job runs, then late fee (capped) and penalty APR trigger per policy `[FR-61]` | 8 |
| CARD-062 | Charge-off workflow at 180 DPD | Given an account reaches 180 days past due, when the batch job runs, then it's flagged for charge-off and collections handoff `[FR-61]` | 5 |
| CARD-063 | Monthly credit bureau reporting (Metro 2) | Given month-end, when the reporting job runs, then account status exports in Metro 2 format to all 3 bureaus `[FR-62]` — *Reg: FCRA* | 8 |
| CARD-064 | Bureau dispute reinvestigation (e-OSCAR/ACDV) | Given a bureau dispute (ACDV) is received, when processed, then reinvestigation completes within 30 days `[FR-62]` | 8 |

**Epic 3.2 Total: 37 pts**

**PHASE 3 TOTAL: 61 pts**

---

## PHASE 4 — Advanced Channels & Growth

### EPIC 4.1: Digital Wallet & Tokenization
*`[FR-32–FR-35]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-065 | Wallet provisioning (Apple/Google/Samsung Pay) | Given a cardholder adds card to wallet, when provisioned, then a network token (VTS/MDES) is issued, mapping DPAN↔FPAN securely `[FR-32,33]` | 13 |
| CARD-066 | Token lifecycle sync with card status | Given a physical card is locked/closed, when status changes, then linked wallet tokens suspend/delete accordingly `[FR-34]` | 5 |
| CARD-067 | Card-on-file network tokenization | Given a merchant stores card-on-file, when tokenized, then a network token (not raw PAN) is used `[FR-35]` | 8 |

**Epic 4.1 Total: 26 pts**

### EPIC 4.2: Rewards & Loyalty
*`[FR-63–FR-64]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-068 | Rewards accrual engine | Given a qualifying transaction, when posted, then points/cashback accrue per category multiplier `[FR-63]` | 8 |
| CARD-069 | Rewards reversal on dispute/refund | Given a transaction is disputed/refunded, when resolved, then associated rewards reverse `[FR-64]` | 3 |

**Epic 4.2 Total: 11 pts**

### EPIC 4.3: Business/Commercial Cards
*`[FR-78–FR-83]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-070 | Company entity & employee cardholder model | Given a business applies, when onboarded, then a Company entity links to multiple Employee Cardholder records `[FR-78]` | 8 |
| CARD-071 | Enhanced KYB / beneficial ownership check | Given a business application, when processed, then beneficial owners (25%+) are verified per FinCEN CDD Rule `[FR-83]` — *Reg: BSA/CDD* | 8 |
| CARD-072 | Hierarchical spend controls (company/dept/employee) | Given a Company Admin sets policy, when applied, then limits cascade correctly to department and employee level `[FR-79]` | 8 |
| CARD-073 | Business card protection-rules differentiation | Given a business card dispute/rate change, when processed, then Reg E/Z consumer protections are correctly NOT auto-applied unless facts-and-circumstances test qualifies `[FR-80]` | 5 |
| CARD-074 | Expense reporting export integration | Given transactions post, when exported, then receipt/GL-coded data is available to accounting system integration `[FR-81]` | 8 |
| CARD-075 | Centralized vs. individual billing model | Given a company selects billing model, when statements generate, then either single company invoice or per-employee invoicing applies `[FR-82]` | 5 |

**Epic 4.3 Total: 42 pts**

**PHASE 4 TOTAL: 79 pts**

---

## PHASE 5 — Compliance Operations & Scale

### EPIC 5.1: Regulatory Reporting
*`[FR-67–FR-70]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-076 | CTR generation ($10k+ cash-equivalent loads) | Given a load ≥$10,000, when detected, then a CTR is generated for filing `[FR-67]` — *Reg: BSA* | 5 |
| CARD-077 | SAR case management & e-filing readiness | Given a suspicious pattern, when flagged, then a SAR case is created with e-filing-ready export `[FR-68]` | 8 |
| CARD-078 | PCI DSS audit reporting dashboard | Given a compliance review, when requested, then access logs, key-rotation evidence, and CDE scope reports are exportable `[FR-69]` | 8 |
| CARD-079 | Regulatory examiner reporting (Reg E/Z metrics) | Given an exam request, when generated, then Reg E/Z error-resolution SLA compliance metrics export `[FR-70]` | 5 |

**Epic 5.1 Total: 26 pts**

### EPIC 5.2: Dormancy, Escheatment & Retention
*`[FR-57], [FR-71]`*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-080 | Dormant account detection job | Given no activity for the policy-defined period, when the batch job runs, then account flags as dormant with cardholder notification `[FR-57]` | 5 |
| CARD-081 | Prepaid balance escheatment workflow | Given a dormant prepaid balance exceeds state dormancy period, when triggered, then balance escheats to the correct state per unclaimed property law `[FR-57]` | 8 |
| CARD-082 | Audit log retention & WORM storage policy | Given retention policy (5-7 yrs), when audit logs age, then they're retained in WORM-compliant storage and purged per policy `[FR-71]` | 5 |

**Epic 5.2 Total: 18 pts**

### EPIC 5.3: Non-Functional Hardening
*NFR section — performance, DR, accessibility*

| Story ID | Title | Acceptance Criteria | Points |
|---|---|---|---|
| CARD-083 | Load testing for peak (holiday) volume | Given simulated peak traffic, when load tested, then auth engine sustains P99 <300ms at target TPS | 8 |
| CARD-084 | DR failover for authorization engine | Given a regional outage simulation, when triggered, then auth engine fails over with near-zero data loss (RPO~0) | 13 |
| CARD-085 | WCAG 2.1 AA accessibility audit (digital channels) | Given the card servicing app/web, when audited, then it passes WCAG 2.1 AA | 8 |

**Epic 5.3 Total: 29 pts**

**PHASE 5 TOTAL: 73 pts**

---

## Grand Summary

| Phase | Epics | Stories | Points |
|---|---|---|---|
| Phase 0 — Platform Foundations | 2 | 9 | 73 |
| Phase 1 — MVP Core Lifecycle | 5 | 26 | 171 |
| Phase 2 — Transaction Lifecycle & Protection | 4 | 20 | 143 |
| Phase 3 — Credit & Billing | 2 | 8 | 61 |
| Phase 4 — Advanced Channels & Growth | 3 | 11 | 79 |
| Phase 5 — Compliance Ops & Scale | 3 | 10 | 73 |
| **TOTAL** | **19** | **84** | **600 pts** |

*Rough sizing only — recommend re-pointing with your actual team in a planning-poker session before committing to sprints.*

---

## Suggested Sprint Sequencing (2-week sprints, indicative)

1. **Sprints 1-3**: Epic 0.1, 0.2 (foundations — nothing ships to users yet, but everything after depends on this)
2. **Sprints 4-8**: Epics 1.1–1.5 (MVP — by end of this, a debit card can be applied for, issued, activated, and used for a real-time purchase with basic lock/unlock)
3. **Sprints 9-12**: Epics 2.1–2.4 (transaction completeness — settlement, disputes, fraud — required before any real money moves at scale)
4. **Sprints 13-15**: Epics 3.1–3.2 (unlocks the credit product specifically)
5. **Sprints 16-18**: Epics 4.1–4.3 (wallet, rewards, business cards — growth features)
6. **Sprints 19-20**: Epic 5.1–5.3 (compliance hardening, DR, scale testing — pre-launch gate)

---

## Notes for Oracle DB Design (Step 2 continuation)

Each Epic above maps to a bounded context that should become a **schema or set of related tables**:
- Epic 0.1 → `CUSTOMER`, `ACCOUNT`, `CARD`, `CARD_PRODUCT`, `AUDIT_LOG`, `TOKEN_VAULT` (PCI-isolated schema)
- Epic 1.1 → `APPLICATION`, `KYC_CHECK`, `OFAC_SCREEN_RESULT`, `ADVERSE_ACTION_NOTICE`
- Epic 1.4 → `AUTHORIZATION`, `AUTH_HOLD`, `FRAUD_SCORE`, `DECLINE_REASON`
- Epic 2.1 → `TRANSACTION`, `CLEARING_RECORD`, `FEE`
- Epic 2.2 → `DISPUTE_CASE`, `CHARGEBACK`, `SAR_CASE`
- Epic 3.1/3.2 → `STATEMENT`, `INTEREST_CALC`, `PAYMENT`, `BUREAU_REPORT`
- Epic 4.1 → `WALLET_TOKEN`
- Epic 4.3 → `COMPANY`, `EMPLOYEE_CARDHOLDER`, `SPEND_POLICY`

*This mapping will be the direct input when we move to the Oracle ER diagram / DDL design session.*

---

*End of Jira Epics & Stories v1.0 — ready for import (CSV/Jira API) or manual entry. Next: Oracle physical data model design, or Step 3 process documentation — your call.*
