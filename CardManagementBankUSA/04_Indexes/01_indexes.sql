-- ============================================================================
-- Indexes - Epic 0.1
-- (PK/UK columns already get a unique index automatically in Oracle; these are the
--  additional FK / lookup-column indexes worth adding for a schema this size.)
-- ============================================================================

CREATE INDEX IDX_ACCOUNT_CUSTOMER      ON CM_ACCOUNT (CUSTOMER_ID);
CREATE INDEX IDX_CARD_ACCOUNT           ON CM_CARD (ACCOUNT_ID);
CREATE INDEX IDX_CARD_PRODUCT           ON CM_CARD (CARD_PRODUCT_ID);
CREATE INDEX IDX_CARD_TOKEN              ON CM_CARD (CARD_TOKEN_ID);
CREATE INDEX IDX_CARD_STATUS              ON CM_CARD (CARD_STATUS);

CREATE INDEX IDX_AUDITLOG_TABLE_RECORD     ON CM_AUDIT_LOG (TABLE_NAME, RECORD_ID);
CREATE INDEX IDX_AUDITLOG_CHANGED_DATE      ON CM_AUDIT_LOG (CHANGED_DATE);

CREATE INDEX IDX_USERROLE_APPUSER            ON CM_USER_ROLE_MAP (APP_USER_ID);
CREATE INDEX IDX_ACCESSLOG_CARD               ON CM_DATA_ACCESS_LOG (CARD_ID);
CREATE INDEX IDX_ACCESSLOG_USER                ON CM_DATA_ACCESS_LOG (APP_USER_ID);

CREATE INDEX IDX_OFAC_WATCHLIST_NAME             ON CM_OFAC_WATCHLIST (NAME_NORMALIZED);
CREATE INDEX IDX_OFAC_SCREENRESULT_PARTY          ON CM_OFAC_SCREEN_RESULT (PARTY_TYPE, PARTY_ID);
