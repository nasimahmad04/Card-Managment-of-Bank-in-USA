-- ============================================================================
-- Table   : CM_CUSTOMER
-- Story   : CARD-001 - Design core entity schema (Customer, Account, Card, CardProduct)
-- Purpose : Base customer entity. Full KYC/CIP capture happens in Epic 1.1 (CARD-010) -
--           this table only carries the minimal identity fields Epic 0.1 needs to key off.
-- ============================================================================

CREATE TABLE CM_CUSTOMER (
    CUSTOMER_ID       NUMBER(12)        NOT NULL,
    FIRST_NAME        VARCHAR2(50)      NOT NULL,
    LAST_NAME         VARCHAR2(50)      NOT NULL,
    DATE_OF_BIRTH     DATE              NOT NULL,
    SSN_LAST4         VARCHAR2(4)       NOT NULL,
    EMAIL             VARCHAR2(100)     NOT NULL,
    PHONE_NUMBER      VARCHAR2(15)      NOT NULL,
    CUSTOMER_TYPE     VARCHAR2(15)      DEFAULT 'CONSUMER' NOT NULL, -- CONSUMER | BUSINESS (Epic 4.3)
    CUSTOMER_STATUS   VARCHAR2(15)      DEFAULT 'ACTIVE' NOT NULL,
    CREATED_DATE      DATE              DEFAULT SYSDATE NOT NULL,
    CREATED_BY        VARCHAR2(30)      DEFAULT USER NOT NULL,
    UPDATED_DATE      DATE,
    UPDATED_BY        VARCHAR2(30)
);

COMMENT ON TABLE  CM_CUSTOMER IS 'Base customer entity - CARD-001 core schema';
COMMENT ON COLUMN CM_CUSTOMER.SSN_LAST4     IS 'Last 4 digits only - full SSN is out of scope for this schema (belongs in a separate PII vault, same pattern as PAN)';
COMMENT ON COLUMN CM_CUSTOMER.CUSTOMER_TYPE IS 'CONSUMER | BUSINESS';
