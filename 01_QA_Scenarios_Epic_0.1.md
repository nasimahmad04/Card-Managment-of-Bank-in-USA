# QA Test Scenarios — Epic 0.1: Core Data Model & Security Baseline

Each scenario maps to a story's acceptance criteria. Positive (P) scenarios prove the
happy path; Negative (N) scenarios prove the system correctly rejects bad input/misuse.
Execute `02_QA_Scenarios_Epic_0.1.sql` to run all of these as an automated smoke suite
(prints PASS/FAIL per scenario via DBMS_OUTPUT).

---

## CARD-001 — Core entity schema (Customer/Account/Card/CardProduct)

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 1.1 | Create a customer, open an account against them, create a DEBIT card product, issue a card | P | All 4 rows created; FK chain Card→Account→Customer and Card→CardProduct resolves correctly |
| 1.2 | Create 3 card products with `product_type` = DEBIT, CREDIT, PREPAID respectively | P | All 3 accepted; `PRODUCT_TYPE` column correctly discriminates them in one physical table |
| 1.3 | Attempt to create a card product with `product_type` = 'CRYPTO' | N | Rejected by `CK_CARDPRODUCT_TYPE` check constraint |
| 1.4 | Attempt to issue a card against a non-existent `ACCOUNT_ID` | N | Rejected — custom error (account not found) before any card row is written |
| 1.5 | Attempt to open an account for a non-existent `CUSTOMER_ID` | N | Rejected by FK constraint `FK_ACCOUNT_CUSTOMER` / custom check |
| 1.6 | Attempt to create a customer with a duplicate email | N | Rejected by `UK_CUSTOMER_EMAIL` |

## CARD-002 — PAN tokenization/vaulting

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 2.1 | Tokenize a valid 16-digit PAN | P | Returns a `TOKEN_ID`; `CM_TOKEN_VAULT.PAN_ENCRYPTED` is non-null binary (not plain text); `PAN_LAST4` matches input's last 4 |
| 2.2 | Confirm `CM_CARD` table has no column capable of holding a raw PAN | P | Structural check — `USER_TAB_COLUMNS` for `CM_CARD` shows no PAN-shaped column, only `CARD_TOKEN_ID` and `CARD_NUMBER_MASKED` |
| 2.3 | Detokenize via `PKG_TOKEN_VAULT.detokenize_pan` and compare to original PAN | P | Returned value exactly matches the original raw PAN (round-trip integrity) |
| 2.4 | Tokenize the same PAN twice | P | Second call returns the *same* `TOKEN_ID` (idempotent, `UK_TOKEN_PAN_HASH` enforced) rather than creating a duplicate vault entry |
| 2.5 | Attempt to tokenize a non-numeric / wrong-length string (`'ABCD1234'`) | N | Rejected — `ex_invalid_pan` custom exception |
| 2.6 | Attempt to `detokenize_pan` with a `TOKEN_ID` that doesn't exist | N | Rejected — `ex_card_not_found` custom exception |
| 2.7 | Attempt to `UPDATE CM_CARD SET CARD_TOKEN_ID = <different token>` after issuance | N | Rejected by `TRG_CM_CARD_TOKEN_READONLY` |

## CARD-003 — PCI DSS CDE network segmentation (documentation register)

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 3.1 | Query `CM_CDE_ASSET_SCOPE` for all objects with `IN_CDE_SCOPE = 'Y'` | P | Returns `CM_TOKEN_VAULT` and `PKG_TOKEN_VAULT` with segmentation notes populated |
| 3.2 | Confirm `CM_CARD` is explicitly registered as out-of-scope with a reason | P | Returns 1 row, `IN_CDE_SCOPE = 'N'`, note explains why |

*(Actual VLAN/VPC segmentation is verified outside the database — see the epic scope
note. This scenario only validates the audit-evidence register the story calls for.)*

## CARD-004 — Immutable audit log

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 4.1 | Insert a new card, then activate it (status ISSUED→ACTIVE) | P | Two `CM_AUDIT_LOG` rows exist for that `CARD_ID`: one INSERT, one UPDATE with `OLD_VALUE`='ISSUED', `NEW_VALUE`='ACTIVE' |
| 4.2 | Update an account's balance | P | A `CM_AUDIT_LOG` row is written automatically — no application code called the audit table directly |
| 4.3 | Attempt `UPDATE CM_AUDIT_LOG SET NEW_VALUE = 'TAMPERED' WHERE AUDIT_ID = <existing>` | N | Rejected by `TRG_CM_AUDIT_LOG_IMMUTABLE` — `ex_audit_log_immutable` |
| 4.4 | Attempt `DELETE FROM CM_AUDIT_LOG WHERE AUDIT_ID = <existing>` | N | Rejected by the same trigger |
| 4.5 | Cause the primary DML to fail after the audit trigger fires (e.g. a subsequent check constraint violation in the same statement) | N | Whole statement rolls back including the CM_CARD/CM_ACCOUNT change — audit log for that specific write is correctly absent (no orphaned entry for a change that never happened) |

## CARD-005 — RBAC framework

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 5.1 | Assign a test user the `AGENT` role, call `get_masked_pan` | P | Returns PAN masked to last-4 only (`************1234`) |
| 5.2 | Assign a test user the `ANALYST` role, call `get_masked_pan` | P | Returns PAN masked to first-6 + last-4 (BIN visible for pattern analysis) |
| 5.3 | Assign a test user the `COMPLIANCE` role, call `get_masked_pan` | P | Returns the **full** unmasked PAN |
| 5.4 | After each of 5.1–5.3, query `CM_DATA_ACCESS_LOG` for that `CARD_ID` | P | One new row per call, `PAN_VISIBILITY_USED` matches what was actually returned — access is logged regardless of role |
| 5.5 | Call `get_masked_pan` for a user with no row in `CM_USER_ROLE_MAP` | N | Rejected — `ex_role_not_found` |
| 5.6 | Re-assign a user from `AGENT` to `COMPLIANCE` via `assign_role`, then call `get_masked_pan` | P | Old role assignment gets `END_DATE` populated; new calls resolve to `COMPLIANCE` visibility; exactly one active (END_DATE IS NULL) mapping exists per user at a time |
| 5.7 | Attempt to insert a role with `PAN_VISIBILITY = 'ALWAYS_SHOW'` | N | Rejected by `CK_ROLE_PAN_VISIBILITY` |

## CARD-006 — OFAC/sanctions screening

| # | Scenario | Type | Expected Result |
|---|---|---|---|
| 6.1 | Seed `CM_OFAC_WATCHLIST` with a known name, screen a customer with an unrelated name | P | `screen_party` returns `NO_MATCH`; a row is written to `CM_OFAC_SCREEN_RESULT` with `MATCHED_WATCHLIST_ID` = NULL |
| 6.2 | Screen a customer whose name+DOB exactly match a watchlist entry | P | Returns `MATCH`, `MATCH_SCORE` = 100, `MATCHED_WATCHLIST_ID` populated |
| 6.3 | Screen a customer whose name matches a watchlist entry but DOB does not | P | Returns `REVIEW` (not an automatic hard match/block — flagged for manual review), `MATCH_SCORE` = 85 |
| 6.4 | Confirm screening completes fast enough to be usable inline in an application flow | P | Wall-clock timing of `screen_party` call is sub-second against a watchlist of representative size (perf smoke test, not a formal load test — that's CARD-083 in Epic 5.3) |
| 6.5 | Attempt to call `screen_party` with `p_party_type = 'VENDOR'` | N | Rejected — invalid party type raised explicitly |

---

## Out of scope for Epic 0.1 QA (covered by later epics)
- Actual CIP/KYC document verification → CARD-010 (Epic 1.1)
- Real OFAC provider API integration (this epic only screens against a local cache) → future hardening story
- EMV chip personalization, PIN generation → Epic 1.2 / 1.3
- Real-time authorization performance (<300ms P99 under load) → CARD-025, CARD-083
