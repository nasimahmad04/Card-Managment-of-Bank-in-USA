-- ============================================================================
-- Table   : CM_CARD_PRODUCT
-- Story   : CARD-001 - Design core entity schema
-- Purpose : Product catalog. Carries the `product_type` discriminator required by the
--           acceptance criteria: "support all 3 products (debit/credit/prepaid) via a
--           product_type discriminator". Every card issued (CM_CARD) references exactly
--           one product, so its product_type is inherited/derivable, not duplicated.
-- ============================================================================

CREATE TABLE CM_CARD_PRODUCT (
    CARD_PRODUCT_ID    NUMBER(6)       NOT NULL,
    PRODUCT_CODE       VARCHAR2(20)    NOT NULL,
    PRODUCT_NAME       VARCHAR2(100)   NOT NULL,
    PRODUCT_TYPE       VARCHAR2(10)    NOT NULL,   -- DEBIT | CREDIT | PREPAID  <-- discriminator
    CARD_NETWORK       VARCHAR2(15)    NOT NULL,   -- VISA | MASTERCARD | AMEX | DISCOVER
    DAILY_LIMIT_AMT    NUMBER(12,2)    DEFAULT 1000 NOT NULL,
    MIN_AGE_YEARS      NUMBER(3)       DEFAULT 18 NOT NULL,
    IS_ACTIVE          CHAR(1)         DEFAULT 'Y' NOT NULL,
    CREATED_DATE       DATE            DEFAULT SYSDATE NOT NULL,
    CREATED_BY         VARCHAR2(30)    DEFAULT USER NOT NULL
);

COMMENT ON TABLE  CM_CARD_PRODUCT IS 'Card product catalog - CARD-001. product_type is the discriminator supporting debit/credit/prepaid from one physical model.';
COMMENT ON COLUMN CM_CARD_PRODUCT.PRODUCT_TYPE IS 'Discriminator: DEBIT | CREDIT | PREPAID';
