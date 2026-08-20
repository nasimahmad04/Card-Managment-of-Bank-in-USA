-- ============================================================================
-- Table   : CM_ACCOUNT
-- Story   : CARD-001 - Design core entity schema
-- Purpose : Financial account a customer holds; one customer can have multiple accounts
--           (e.g. a checking account for debit, a credit line for credit product).
--           Cards are issued against an Account, not directly against a Customer.
-- ============================================================================

CREATE TABLE CM_ACCOUNT (
    ACCOUNT_ID         NUMBER(14)      NOT NULL,
    CUSTOMER_ID        NUMBER(12)      NOT NULL,
    ACCOUNT_NUMBER     VARCHAR2(20)    NOT NULL,   -- bank-facing account number (not a PAN)
    ACCOUNT_TYPE       VARCHAR2(15)    NOT NULL,   -- DEBIT | CREDIT | PREPAID (mirrors product_type)
    CURRENT_BALANCE    NUMBER(14,2)    DEFAULT 0 NOT NULL,
    AVAILABLE_BALANCE  NUMBER(14,2)    DEFAULT 0 NOT NULL,
    CREDIT_LIMIT       NUMBER(14,2)    ,           -- only populated for CREDIT accounts
    ACCOUNT_STATUS     VARCHAR2(15)    DEFAULT 'ACTIVE' NOT NULL,
    OPEN_DATE          DATE            DEFAULT SYSDATE NOT NULL,
    CLOSE_DATE         DATE            ,
    CREATED_DATE       DATE            DEFAULT SYSDATE NOT NULL,
    CREATED_BY         VARCHAR2(30)    DEFAULT USER NOT NULL,
    UPDATED_DATE       DATE            ,
    UPDATED_BY         VARCHAR2(30)
);

COMMENT ON TABLE  CM_ACCOUNT IS 'Financial account owned by a customer - CARD-001 core schema. Cards are issued against an account.';
COMMENT ON COLUMN CM_ACCOUNT.ACCOUNT_TYPE   IS 'DEBIT | CREDIT | PREPAID';
COMMENT ON COLUMN CM_ACCOUNT.ACCOUNT_STATUS IS 'ACTIVE | DORMANT | CLOSED | FROZEN';
