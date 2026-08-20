-- ============================================================================
-- Table   : CM_OFAC_SCREEN_RESULT
-- Story   : CARD-006 - OFAC/sanctions screening service integration
-- Purpose : Stores the match/no-match result of every screening run, per acceptance
--           criteria: "when screened, then a real-time match/no-match result returns".
--           Screened party may be a CUSTOMER (at application time, Epic 1.1) or, in
--           later epics, a transaction counterparty - PARTY_TYPE keeps this generic.
-- ============================================================================

CREATE TABLE CM_OFAC_SCREEN_RESULT (
    SCREEN_RESULT_ID    NUMBER(18)     NOT NULL,
    PARTY_TYPE            VARCHAR2(15) NOT NULL,   -- CUSTOMER | TRANSACTION_PARTY
    PARTY_ID                NUMBER(14) NOT NULL,   -- e.g. CUSTOMER_ID
    SCREEN_RESULT             VARCHAR2(10) NOT NULL, -- MATCH | NO_MATCH | REVIEW
    MATCHED_WATCHLIST_ID        NUMBER(10),         -- FK -> CM_OFAC_WATCHLIST, NULL if NO_MATCH
    MATCH_SCORE                   NUMBER(5,2),      -- 0-100 confidence score
    SCREENED_DATE                   TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    SCREENING_PROVIDER                VARCHAR2(30) DEFAULT 'INTERNAL_OFAC_CACHE'
);

COMMENT ON TABLE CM_OFAC_SCREEN_RESULT IS 'Match/no-match result of each OFAC screening run - CARD-006 / [FR-02], Reg: BSA/OFAC';
