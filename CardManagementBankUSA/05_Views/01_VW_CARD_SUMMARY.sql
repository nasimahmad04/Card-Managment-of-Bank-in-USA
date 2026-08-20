-- ============================================================================
-- View    : VW_CARD_SUMMARY
-- Story   : CARD-001 (convenience read model) / CARD-005 (never exposes raw PAN)
-- Purpose : Standard read view joining Card -> Account -> Customer -> Product for
--           reporting/UI use. Deliberately exposes only CARD_NUMBER_MASKED (never the
--           token or vault) - callers who need role-based unmasking must go through
--           PKG_RBAC_ACCESS.get_masked_pan(), which also logs the access.
-- ============================================================================

CREATE OR REPLACE VIEW VW_CARD_SUMMARY AS
SELECT
    c.CARD_ID,
    c.CARD_NUMBER_MASKED,
    c.CARD_STATUS,
    c.EXPIRY_DATE,
    c.ISSUE_DATE,
    c.ACTIVATION_DATE,
    cp.PRODUCT_CODE,
    cp.PRODUCT_NAME,
    cp.PRODUCT_TYPE,
    cp.CARD_NETWORK,
    a.ACCOUNT_ID,
    a.ACCOUNT_NUMBER,
    a.ACCOUNT_TYPE,
    a.ACCOUNT_STATUS,
    cu.CUSTOMER_ID,
    cu.FIRST_NAME,
    cu.LAST_NAME,
    cu.CUSTOMER_STATUS
FROM CM_CARD c
JOIN CM_CARD_PRODUCT cp ON cp.CARD_PRODUCT_ID = c.CARD_PRODUCT_ID
JOIN CM_ACCOUNT a       ON a.ACCOUNT_ID       = c.ACCOUNT_ID
JOIN CM_CUSTOMER cu     ON cu.CUSTOMER_ID     = a.CUSTOMER_ID;

COMMENT ON TABLE VW_CARD_SUMMARY IS 'Read model for card/account/customer/product - never exposes token or raw PAN, only the pre-masked display value';
