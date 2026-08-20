-- ============================================================================
-- Package  : PKG_CORE_ENTITY_MGMT (spec)
-- Story    : CARD-001 - Design core entity schema (Customer, Account, Card, CardProduct)
-- Purpose  : Basic CRUD/orchestration over the 4 core entities so the schema can be
--            exercised end-to-end for QA (full detail capture for these entities is
--            genuinely built out in later epics - 1.1 Application & Origination,
--            1.2 Card Issuance & Personalization - this is the Epic 0.1 foundation
--            version).
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_CORE_ENTITY_MGMT AS

    FUNCTION create_customer (
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_ssn_last4     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_phone_number  IN VARCHAR2,
        p_customer_type IN VARCHAR2 DEFAULT 'CONSUMER'
    ) RETURN NUMBER;   -- returns CUSTOMER_ID

    FUNCTION open_account (
        p_customer_id     IN NUMBER,
        p_account_number  IN VARCHAR2,
        p_account_type    IN VARCHAR2,
        p_credit_limit    IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;    -- returns ACCOUNT_ID

    FUNCTION create_card_product (
        p_product_code   IN VARCHAR2,
        p_product_name   IN VARCHAR2,
        p_product_type   IN VARCHAR2,
        p_card_network   IN VARCHAR2,
        p_daily_limit    IN NUMBER DEFAULT 1000,
        p_min_age_years  IN NUMBER DEFAULT 18
    ) RETURN NUMBER;    -- returns CARD_PRODUCT_ID

    -- Requests + issues a card in one call: tokenizes the PAN (CARD-002), validates
    -- account is active and product is active and customer meets min-age, then inserts
    -- the CM_CARD row referencing the token (never the raw PAN).
    FUNCTION issue_card (
        p_account_id      IN NUMBER,
        p_card_product_id IN NUMBER,
        p_raw_pan         IN VARCHAR2,
        p_expiry_date     IN DATE
    ) RETURN NUMBER;    -- returns CARD_ID

    PROCEDURE activate_card (
        p_card_id IN NUMBER
    );

    PROCEDURE change_card_status (
        p_card_id     IN NUMBER,
        p_new_status  IN VARCHAR2,
        p_reason      IN VARCHAR2 DEFAULT NULL
    );

END PKG_CORE_ENTITY_MGMT;
/
