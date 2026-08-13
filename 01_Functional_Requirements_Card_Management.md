# Functional Requirements Document (FRD)
## Bank Card Management System — United States
**Version:** 1.0 (Draft) | **Date:** August 14, 2026 | **Status:** For Review

---

## 1. Purpose & Scope

This document defines the functional requirements for a **real-time Card Management System (CMS)** for a US-based bank, covering **debit, credit, and prepaid cards** (physical and virtual), across their full lifecycle — from application through closure — in compliance with US banking regulations.

This FRD is Step 1 of a 4-step plan:
1. **Functional requirements** (this document)
2. Jira Epics/Stories → Oracle DB design
3. Process & code documentation
4. Snowflake/DBT/Airflow data warehouse

**In scope:** Card issuance, authorization, transaction posting, disputes, fraud controls, card servicing, statementing, closure, digital wallet provisioning.
**Out of scope (for now):** Core deposit/loan origination, general ledger, branch operations, merchant acquiring side.

---

## 2. Regulatory & Compliance Framework

Every functional requirement below must be traceable to one or more of these. Treat this table as the compliance backbone of the system.

| # | Regulation / Standard | Applies To | Key System Impact |
|---|---|---|---|
| 1 | **Regulation E (EFTA)** | Debit/prepaid cards | Error resolution timelines (10/20/45/90 business days), provisional credit, unauthorized transaction liability limits ($50/$500/unlimited tiers), periodic statement requirements |
| 2 | **Regulation Z (TILA)** | Credit cards | Billing statement content, interest rate disclosures, 21-day grace period before due date, dispute rights (60-day billing error window), payment allocation rules (CARD Act), APR change notices |
| 3 | **Regulation CC** | Funds availability | Hold periods for deposits linked to prepaid/debit accounts |
| 4 | **CARD Act of 2009** | Credit cards | Ability-to-pay checks, restrictions on rate increases, over-limit opt-in, statement due date consistency, marketing to under-21 |
| 5 | **PCI DSS v4.0** | All card data | Cardholder Data Environment (CDE) segmentation, encryption of PAN at rest/in transit, tokenization, key management, access logging, no storage of CVV/full track data post-authorization |
| 6 | **EMV Standards (EMVCo)** | Card issuance | Chip personalization, cryptogram validation (ARQC/ARPC), contactless (EMV Contactless) |
| 7 | **BSA / AML / USA PATRIOT Act** | Card issuance & funding | CIP/KYC at account opening, CTR ($10k+), SAR filing, OFAC/sanctions screening on cardholders and transaction counterparties |
| 8 | **OFAC Sanctions Screening** | All parties | Real-time screening of applicant, merchant (MCC/location), and cross-border transactions |
| 9 | **FCRA** | Credit cards | Credit bureau reporting (Metro 2 format), adverse action notices, dispute reinvestigation (30 days), permissible purpose for pulls |
| 10 | **GLBA (Reg P) / Privacy Rules** | All cards | Customer data privacy notices, opt-out rights, safeguarding of NPI |
| 11 | **NACHA Rules** | ACH-funded prepaid/debit | ACH funding/settlement rules if card linked to ACH rails |
| 12 | **Card Network Rules (Visa/Mastercard/Amex/Discover)** | All cards | Chargeback timelines & reason codes, interchange, authorization message formats (ISO 8583), zero-liability policies |
| 13 | **Regulation II (Durbin Amendment)** | Debit cards | Interchange fee caps (issuers >$10B assets), routing choice (min. 2 unaffiliated networks) |
| 14 | **ADA / Section 508** | Digital channels | Accessible card management UI/statements |
| 15 | **State-specific consumer protection laws** | Varies | E.g., California DFPI rules, unclaimed property/escheatment for dormant prepaid balances |
| 16 | **CFPB Prepaid Rule (Reg E subpart)** | Prepaid/GPR cards | Fee disclosures ("short-form"), error resolution parity with debit |
| 17 | **FFIEC Authentication Guidance** | Digital/online card servicing | Multi-factor authentication for card management self-service |

---

## 3. Actors / Personas

| Actor | Description |
|---|---|
| **Applicant/Prospect** | Individual applying for a card (not yet a cardholder) |
| **Cardholder (Primary)** | Approved customer holding a card |
| **Authorized User** | Secondary cardholder on primary's account |
| **Bank Ops / Card Servicing Agent** | Call center / back-office staff |
| **Fraud/Risk Analyst** | Reviews flagged transactions, disputes |
| **Compliance Officer** | Reviews SAR/CTR, audit reports |
| **Merchant (external)** | Transaction counterparty, via acquirer/network |
| **Card Network (Visa/MC/Amex/Discover)** | Authorization routing, clearing/settlement |
| **Issuer Processor (e.g., TSYS/FIS/Fiserv, or in-house)** | Real-time auth engine |
| **Third-Party Wallet Provider** | Apple Pay, Google Pay, Samsung Pay (tokenization) |
| **Credit Bureau** | Equifax/Experian/TransUnion (credit cards only) |
| **System Admin** | Configures products, limits, MCC rules |

---

## 4. Functional Requirements

Each requirement is tagged **[FR-xx]** for downstream Jira story mapping, with the driving regulation(s) noted.

### 4.1 Card Application & Origination

- **FR-01**: System shall capture applicant PII (name, SSN/ITIN, DOB, address, income) and perform **CIP/KYC** verification before card issuance. *(BSA/PATRIOT Act)*
- **FR-02**: System shall perform **OFAC/sanctions list screening** on applicant in real time; block/hold issuance on positive match pending review.
- **FR-03**: For credit cards, system shall pull credit bureau report (FCRA permissible purpose), run **ability-to-pay** assessment. *(CARD Act)*
- **FR-04**: System shall generate **adverse action notice** within required timeframe if application denied. *(FCRA/ECOA)*
- **FR-05**: System shall support product eligibility rules (debit tied to DDA, prepaid GPR, secured/unsecured credit, business cards).
- **FR-06**: System shall capture consumer consent/e-sign for card agreement, privacy notice (GLBA), and prepaid short-form fee disclosure if applicable.
- **FR-07**: System shall support **instant-issue** (in-branch printed) and **standard mail issuance** workflows.

### 4.2 Card Issuance & Personalization

- **FR-08**: System shall generate PAN (via BIN range assigned by network), expiration date, and CVV per network/PCI specs; PAN generation shall never be predictable/sequential in a way that violates PCI DSS.
- **FR-09**: System shall support **EMV chip personalization** files sent to card manufacturer (physical) and **virtual card** generation (digital-first, no physical plastic).
- **FR-10**: System shall support **card art selection**, multiple card designs per product.
- **FR-11**: System shall generate and securely deliver PIN (PIN mailer, IVR set, or app-based set) — PIN never stored in clear text/reversibly encrypted; only PVV/PIN block validation.
- **FR-12**: System shall support reissue-before-expiry (auto-generate replacement ~60-90 days before expiration) preserving PAN or generating new PAN per network rules.
- **FR-13**: System shall support **instant digital card issuance** to mobile app immediately upon approval, usable for online purchases before physical card arrives.

### 4.3 Card Activation

- **FR-14**: System shall support activation via mobile app, IVR, web, or first-PIN-transaction, with identity verification (last 4 SSN, DOB, or OTP).
- **FR-15**: System shall enforce **card must be activated** before any authorization is approved (status check in real-time auth flow).
- **FR-16**: System shall log activation channel, timestamp, device/IP for fraud analytics.

### 4.4 Real-Time Authorization Processing

- **FR-17**: System shall process **ISO 8583** (or ISO 20022 where applicable) authorization requests from network in **sub-second** response time (typically <300ms end-to-end).
- **FR-18**: Authorization engine shall validate in real time, in sequence: card status (active/blocked/expired/lost-stolen), available balance/credit limit, velocity limits, merchant category (MCC) restrictions, geographic restrictions, spend controls set by cardholder, fraud score/rules engine, EMV cryptogram (ARQC) validation.
- **FR-19**: System shall support **partial authorization** (for prepaid/debit where available balance < requested amount, per network rules).
- **FR-20**: System shall place a **hold (authorization hold)** on available balance for approved authorizations; hold shall auto-expire per network rules (typically 3-10 days) if not matched to clearing.
- **FR-21**: System shall support **incremental authorizations** and **authorization reversals** (full/partial) from merchant/network.
- **FR-22**: System shall support **PIN-based** and **signature-based** and **contactless (no-CVM)** authorization flows per EMV rules.
- **FR-23**: System shall support **card-not-present (CNP)** transactions with CVV2/AVS validation and 3-D Secure (3DS2) step-up for e-commerce.
- **FR-24**: System shall support **recurring/subscription transaction** flagging and **account updater** service (auto-update merchant-stored card-on-file when card is reissued) — Visa Account Updater / Mastercard Automatic Billing Updater.
- **FR-25**: System shall decline transactions with a specific **decline reason code** (insufficient funds, card blocked, fraud suspected, CVV mismatch, expired card, over limit) mapped to network response codes.

### 4.5 Card Controls (Self-Service, Real-Time)

- **FR-26**: Cardholder shall be able to **lock/unlock** card instantly via app/web; lock shall reflect in authorization engine within seconds.
- **FR-27**: Cardholder shall be able to set **spend controls**: merchant category blocks (e.g., gambling, adult content), transaction type blocks (online, international, ATM), per-transaction limit, daily/monthly limit.
- **FR-28**: Cardholder shall be able to set **geographic/travel controls** (enable international usage for date range).
- **FR-29**: System shall support **authorized user** card issuance with independent controls/limits set by primary cardholder.
- **FR-30**: Cardholder shall receive **real-time push/SMS/email alerts** on transaction, decline, card lock/unlock, and control changes (configurable thresholds).
- **FR-31**: Cardholder shall be able to report card **lost/stolen** instantly, triggering immediate block and reissuance workflow; **zero-liability** application per network rules.

### 4.6 Digital Wallet & Tokenization

- **FR-32**: System shall support **card provisioning to digital wallets** (Apple Pay, Google Pay, Samsung Pay) via network tokenization service (Visa Token Service / Mastercard MDES).
- **FR-33**: System shall map **Device PAN (DPAN)** to actual PAN (FPAN) securely; token vault shall never expose FPAN to wallet provider.
- **FR-34**: System shall support token life-cycle events (suspend, resume, delete) synced with physical card status changes.
- **FR-35**: System shall support **Card-on-File tokenization** for e-commerce merchants (network tokens, not raw PAN).

### 4.7 Transaction Posting, Clearing & Settlement

- **FR-36**: System shall process **clearing/settlement files** from network (typically T+1 or T+2), matching to authorizations, converting holds to posted transactions.
- **FR-37**: System shall handle **unmatched clearing** (settlement without prior auth) and **force-post** transactions.
- **FR-38**: System shall calculate and post **interchange** (received/paid) for reporting.
- **FR-39**: System shall support **multi-currency transactions** with FX conversion and foreign transaction fee application, per Reg Z/E disclosure rules.
- **FR-40**: System shall support **fee posting**: annual fee, late fee, over-limit fee, foreign transaction fee, ATM fee, replacement card fee — all per disclosed schedule (Reg Z/CARD Act limits on penalty fees).

### 4.8 Disputes & Chargebacks

- **FR-41**: Cardholder shall be able to initiate a **dispute** via app/call center, categorized by reason (fraud, billing error, merchandise not received, duplicate charge, quality dispute).
- **FR-42**: System shall apply **Reg E timelines** for debit/prepaid: acknowledge within specified days, provisional credit within 10 business days (20 for new accounts) if investigation exceeds timeframe, final resolution within 45 days (90 for certain cases).
- **FR-43**: System shall apply **Reg Z billing error rights** for credit: written notice within 60 days of statement, resolve within 2 billing cycles (max 90 days), no minimum payment due on disputed amount during investigation.
- **FR-44**: System shall generate **network chargeback** with correct **reason code** (Visa/Mastercard/Amex/Discover specific) and manage representment/re-presentment cycles and timeframes.
- **FR-45**: System shall track dispute case status (open, provisional credit issued, representment received, resolved-customer favor, resolved-merchant favor, arbitration) with full audit trail.
- **FR-46**: System shall auto-generate **SAR** (Suspicious Activity Report) trigger for dispute patterns suggesting fraud rings or money laundering.

### 4.9 Fraud & Risk Management

- **FR-47**: System shall integrate a **real-time fraud scoring engine** (rules-based + ML) evaluating each authorization (velocity, geo-impossible-travel, device fingerprint, merchant risk).
- **FR-48**: System shall support **step-up authentication** (OTP, 3DS challenge) for risk-scored transactions.
- **FR-49**: System shall support case management for fraud analysts to review/release/block flagged transactions and cards.
- **FR-50**: System shall auto-block card and notify cardholder on confirmed fraud pattern; issue replacement card with new PAN.
- **FR-51**: System shall maintain **negative file / watchlist** of known-fraud PANs, devices, and merchants.

### 4.10 Card Servicing & Lifecycle

- **FR-52**: System shall support card **status lifecycle**: Pending → Issued → Active → Suspended/Locked → Lost/Stolen → Closed → Expired, with defined valid transitions and audit log.
- **FR-53**: System shall support **card replacement** (damaged, lost, stolen, compromised) with option to retain or change PAN, and expedited shipping.
- **FR-54**: System shall support **PIN reset/change** via ATM, IVR, or app with re-verification.
- **FR-55**: System shall support **card closure** (voluntary or bank-initiated) — settle pending authorizations, block future auths, handle final balance (refund for prepaid, payoff for credit).
- **FR-56**: System shall support **credit limit management**: increase (soft/hard pull per policy), decrease, temporary limit changes.
- **FR-57**: System shall support **dormant/inactive account handling** and, for prepaid, **escheatment** to state per unclaimed property law after defined dormancy period.

### 4.11 Statements, Billing & Payments (Credit Cards)

- **FR-58**: System shall generate **monthly billing statements** per Reg Z content requirements (min. payment, APR, due date, grace period, interest charge calculation detail).
- **FR-59**: System shall calculate **interest** using average daily balance / other disclosed method, applying correct **payment allocation** (payments above minimum applied to highest-APR balance first, per CARD Act).
- **FR-60**: System shall support **payment processing** (ACH, check, wire) with same-day posting per Reg Z requirements, and **autopay** setup.
- **FR-61**: System shall support **delinquency management**: late fee assessment (capped per CARD Act/Reg Z), penalty APR triggers, collections handoff workflow, charge-off at 180 days past due (per regulatory guidance).
- **FR-62**: System shall report account status to **credit bureaus monthly** (Metro 2 format) and support **bureau dispute (ACDV/e-OSCAR)** reinvestigation workflow.

### 4.12 Rewards & Loyalty (if applicable)

- **FR-63**: System shall accrue rewards points/cashback per transaction based on product rules (category multipliers), redeemable via configured channels.
- **FR-64**: System shall reverse rewards on disputed/refunded transactions.

### 4.13 Notifications & Customer Communication

- **FR-65**: System shall send **real-time transaction alerts**, low-balance alerts (prepaid/debit), payment due reminders, and regulatory notices (adverse action, APR change, privacy notice) via configurable channel (push/SMS/email/mail).
- **FR-66**: System shall maintain **audit log** of all communications for compliance evidence.

### 4.14 Reporting, Audit & Compliance Operations

- **FR-67**: System shall generate **CTR** (Currency Transaction Report) for applicable cash-equivalent loads ≥$10,000.
- **FR-68**: System shall support **SAR case management** and e-filing readiness.
- **FR-69**: System shall provide **PCI DSS audit reporting** (access logs, key rotation evidence, CDE scope reports).
- **FR-70**: System shall support **regulatory examiner reporting** (call reports, CFPB complaint data, Reg E/Z error resolution metrics).
- **FR-71**: System shall maintain full **immutable audit trail** for every card/account state change (who, what, when, before/after value) for minimum retention per record-retention policy (typically 5-7 years).

### 4.15 Customer Service / Call Center Support

- **FR-72**: Agents shall have a unified view of card status, recent transactions, disputes, and controls, with role-based access (least privilege, masked PAN display — PCI DSS).
- **FR-73**: System shall support **agent-assisted actions** (lock card, initiate dispute, order replacement) with strong authentication of caller identity first (KBA/OTP).

---

## 5. Non-Functional Requirements (Summary — to be expanded separately)

| Category | Requirement |
|---|---|
| **Performance** | Authorization decisioning < 300ms (P99); system availability 99.99% for auth path |
| **Security** | PCI DSS Level 1 compliance; encryption at rest (AES-256) and in transit (TLS 1.2+); tokenization of PAN in all non-auth systems |
| **Scalability** | Support real-time horizontal scaling for peak (holiday) transaction volumes |
| **Auditability** | Every state change traceable; WORM storage option for audit logs |
| **Disaster Recovery** | RPO/RTO defined for auth engine (near-zero data loss for financial transactions) |
| **Accessibility** | WCAG 2.1 AA for digital card servicing channels |

---

## 6. Preliminary Data Domain Areas (for DB design — Step 2)

*(Names only, not full schema — to be detailed in Jira/Oracle design phase)*

Applicant, Customer, Account, Card, CardProduct, CardStatusHistory, AuthorizationLog, Transaction, Hold, Dispute, Chargeback, FraudCase, CardControl, DigitalWalletToken, Statement, Payment, Fee, RewardsLedger, Notification, ComplianceCase(SAR/CTR), AuditLog, MerchantCategoryRule, LimitConfiguration.

---

## 7. Confirmed Scope Decisions (v1.1)

| Decision | Choice | Impact |
|---|---|---|
| **Product scope** | **Debit + Credit + Prepaid** (full scope) | All FRs in Section 4 apply across all three products; product-specific variants are called out below (7.1) |
| **Issuance model** | **Not yet decided** — system to be designed **issuer-model-agnostic** | Architecture must abstract the "issuing engine" behind an interface so it can run **in-house** or delegate to a **processor/BIN sponsor** (Marqeta, Galileo, i2c, FIS, TSYS) with minimal rework. See 7.2. |
| **Customer segment** | **Both Consumer and Business/Commercial** | Adds a parallel set of requirements for commercial cards (7.3) — different regulatory treatment, different data model (company + employee cardholders) |

### 7.1 Product-Specific Notes (Debit / Credit / Prepaid)

| Area | Debit | Credit | Prepaid (GPR) |
|---|---|---|---|
| Funding source | Linked DDA | Bank-extended credit line | Preloaded balance (no linked DDA required) |
| Governing consumer reg | Reg E | Reg Z | Reg E (CFPB Prepaid Rule — subpart) |
| Credit bureau reporting | No | Yes (FCRA/Metro 2) | No |
| Interest/APR | No | Yes | No |
| Underwriting | Account-opening KYC only | Full credit underwriting (FR-03) | Account-opening KYC (or reduced KYC for retail-loaded cards) |
| Interchange | Durbin-capped (Reg II) if issuer >$10B assets | Uncapped | Durbin-capped if applicable |
| Escheatment | N/A (tied to DDA) | N/A | **Applies** — dormant balance escheatment (FR-57) |
| Statement | Optional/on-demand | **Mandatory monthly** (Reg Z) | Short-form fee disclosure at issuance; transaction history on request |

*Action for Step 2:* Jira epics will be organized so shared card-lifecycle stories (issuance, activation, controls, fraud) are product-agnostic, while billing/statement/interest and escheatment stories are tagged product-specific.

### 7.2 Issuance-Model-Agnostic Requirements (new)

- **FR-74**: System shall expose card issuance, authorization-decisioning, and lifecycle operations via an **abstracted service interface**, allowing the underlying issuing engine to be either the bank's own system-of-record or a third-party processor/BIN sponsor, without changing downstream (CMS/DB/DW) contracts.
- **FR-75**: If a **BIN sponsor/processor** is used, system shall support **webhook/API-based real-time event ingestion** (authorization, clearing, dispute, card-status events) from the processor into the bank's CMS of record.
- **FR-76**: If **in-house issuing**, system shall implement its own ISO 8583/20022 connection to the card network directly (higher compliance burden — full PCI DSS Level 1 scope, EMV key management, network certification).
- **FR-77**: Regardless of model, the **bank remains the regulatory owner** of Reg E/Z compliance, disputes, and consumer communications — processor integrations must expose enough data (timestamps, reason codes) to meet the bank's own compliance SLAs (FR-42, FR-43).

### 7.3 Business / Commercial Card Requirements (new)

- **FR-78**: System shall support a **Company entity** as the primary account holder, with multiple **Employee Cardholders** issued cards against a shared or individually-limited credit line/balance.
- **FR-79**: System shall support **hierarchical spend controls**: company-level policy, department-level limits, individual cardholder limits, settable by a **Company Admin** role.
- **FR-80**: System shall distinguish **consumer protections that do NOT automatically apply to business cards** (e.g., CARD Act ability-to-pay, most Reg Z rate/fee protections, Reg E error-resolution rights) — business cards are governed primarily by **contract terms + UDAAP + state commercial law**, not Reg E/Z, unless the card is used primarily for personal/family purposes (facts-and-circumstances test) or state law extends protections (e.g., some small-business protections in CA, NY).
- **FR-81**: System shall support **expense reporting integration** (receipt capture, GL coding, export to accounting systems) for commercial cardholders.
- **FR-82**: System shall support **centralized billing (single invoice to company)** vs. **individual billing (each employee liable)** models.
- **FR-83**: System shall apply **enhanced KYB (Know Your Business)** diligence at company onboarding — beneficial ownership (25%+ owners per FinCEN CDD Rule), business registration verification — in addition to individual KYC on authorized signers/cardholders.

---

## 8. Assumptions & Remaining Open Questions

1. **Network(s):** Visa, Mastercard, or multi-network routing (Durbin requires ≥2 unaffiliated networks for debit)? *(Still open)*
2. **Issuer size:** Is the bank >$10B in assets? This determines whether Reg II (Durbin interchange cap) applies at all — small issuers are exempt.
3. **Prepaid card type:** Open-loop **GPR (reloadable)** vs. closed-loop/gift vs. payroll card — each has slightly different CFPB Prepaid Rule treatment.
4. **Geographic footprint:** Single-state vs. multi-state — affects which state consumer-protection/escheatment rules apply.
5. Once issuance model (7.2) is decided, the Jira epics in Step 2 can be finalized — until then, epics will be written to be **model-agnostic** with sub-tasks flagged as "in-house only" or "processor-integration only."

---

*End of Draft v1.1 — scope confirmed (Debit + Credit + Prepaid, Consumer + Business). Ready to proceed to Step 2: Jira Epics/Stories for Oracle DB design.*
