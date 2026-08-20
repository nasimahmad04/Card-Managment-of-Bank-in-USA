-- ============================================================================
-- Package  : PKG_CORE_ENTITY_MGMT (body)
-- Story    : CARD-001
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_CORE_ENTITY_MGMT AS

    FUNCTION create_customer (
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_date_of_birth IN DATE,
        p_ssn_last4     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_phone_number  IN VARCHAR2,
        p_customer_type IN VARCHAR2 DEFAULT 'CONSUMER'
    ) RETURN NUMBER
    IS
        v_customer_id NUMBER;
    BEGIN
        v_customer_id := SEQ_CM_CUSTOMER.NEXTVAL;

        INSERT INTO CM_CUSTOMER (
            CUSTOMER_ID, FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, SSN_LAST4,
            EMAIL, PHONE_NUMBER, CUSTOMER_TYPE, CUSTOMER_STATUS, CREATED_DATE, CREATED_BY
        ) VALUES (
            v_customer_id, p_first_name, p_last_name, p_date_of_birth, p_ssn_last4,
            LOWER(p_email), p_phone_number, p_customer_type, 'ACTIVE', SYSDATE, USER
        );

        RETURN v_customer_id;
    END create_customer;


    FUNCTION open_account (
        p_customer_id     IN NUMBER,
        p_account_number  IN VARCHAR2,
        p_account_type    IN VARCHAR2,
        p_credit_limit    IN NUMBER DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_account_id NUMBER;
        v_dummy      NUMBER;
    BEGIN
        BEGIN
            SELECT 1 INTO v_dummy FROM CM_CUSTOMER WHERE CUSTOMER_ID = p_customer_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20530, 'open_account: customer ' || p_customer_id || ' does not exist');
        END;

        v_account_id := SEQ_CM_ACCOUNT.NEXTVAL;

        INSERT INTO CM_ACCOUNT (
            ACCOUNT_ID, CUSTOMER_ID, ACCOUNT_NUMBER, ACCOUNT_TYPE, CURRENT_BALANCE,
            AVAILABLE_BALANCE, CREDIT_LIMIT, ACCOUNT_STATUS, OPEN_DATE, CREATED_DATE, CREATED_BY
        ) VALUES (
            v_account_id, p_customer_id, p_account_number, p_account_type, 0,
            0, p_credit_limit, 'ACTIVE', SYSDATE, SYSDATE, USER
        );

        RETURN v_account_id;
    END open_account;


    FUNCTION create_card_product (
        p_product_code   IN VARCHAR2,
        p_product_name   IN VARCHAR2,
        p_product_type   IN VARCHAR2,
        p_card_network   IN VARCHAR2,
        p_daily_limit    IN NUMBER DEFAULT 1000,
        p_min_age_years  IN NUMBER DEFAULT 18
    ) RETURN NUMBER
    IS
        v_card_product_id NUMBER;
    BEGIN
        v_card_product_id := SEQ_CM_CARD_PRODUCT.NEXTVAL;

        INSERT INTO CM_CARD_PRODUCT (
            CARD_PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE, CARD_NETWORK,
            DAILY_LIMIT_AMT, MIN_AGE_YEARS, IS_ACTIVE, CREATED_DATE, CREATED_BY
        ) VALUES (
            v_card_product_id, p_product_code, p_product_name, p_product_type, p_card_network,
            p_daily_limit, p_min_age_years, 'Y', SYSDATE, USER
        );

        RETURN v_card_product_id;
    END create_card_product;


    FUNCTION issue_card (
        p_account_id      IN NUMBER,
        p_card_product_id IN NUMBER,
        p_raw_pan         IN VARCHAR2,
        p_expiry_date     IN DATE
    ) RETURN NUMBER
    IS
        v_card_id        NUMBER;
        v_token_id       NUMBER;
        v_masked         VARCHAR2(19);
        v_account_status CM_ACCOUNT.ACCOUNT_STATUS%TYPE;
        v_product_active CM_CARD_PRODUCT.IS_ACTIVE%TYPE;
        v_min_age        CM_CARD_PRODUCT.MIN_AGE_YEARS%TYPE;
        v_customer_dob   CM_CUSTOMER.DATE_OF_BIRTH%TYPE;
        v_customer_age   NUMBER;
    BEGIN
        BEGIN
            SELECT ACCOUNT_STATUS INTO v_account_status
            FROM CM_ACCOUNT WHERE ACCOUNT_ID = p_account_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                    'issue_card: account ' || p_account_id || ' does not exist');
        END;

        IF v_account_status != 'ACTIVE' THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_account_not_active_num,
                'issue_card: account ' || p_account_id || ' is not ACTIVE (status=' || v_account_status || ')');
        END IF;

        BEGIN
            SELECT IS_ACTIVE, MIN_AGE_YEARS INTO v_product_active, v_min_age
            FROM CM_CARD_PRODUCT WHERE CARD_PRODUCT_ID = p_card_product_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                    'issue_card: card product ' || p_card_product_id || ' does not exist');
        END;

        IF v_product_active != 'Y' THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_product_inactive_num,
                'issue_card: card product ' || p_card_product_id || ' is not active');
        END IF;

        SELECT cu.DATE_OF_BIRTH INTO v_customer_dob
        FROM CM_ACCOUNT a JOIN CM_CUSTOMER cu ON cu.CUSTOMER_ID = a.CUSTOMER_ID
        WHERE a.ACCOUNT_ID = p_account_id;

        v_customer_age := TRUNC(MONTHS_BETWEEN(SYSDATE, v_customer_dob) / 12);

        IF v_customer_age < v_min_age THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_underage_applicant_num,
                'issue_card: customer age ' || v_customer_age || ' below product minimum ' || v_min_age);
        END IF;

        -- Tokenize the PAN - this is the ONLY place a raw PAN is handled outside the vault package
        v_token_id := PKG_TOKEN_VAULT.tokenize_pan(p_raw_pan);
        v_masked   := PKG_TOKEN_VAULT.get_masked_display(v_token_id);

        v_card_id := SEQ_CM_CARD.NEXTVAL;

        INSERT INTO CM_CARD (
            CARD_ID, ACCOUNT_ID, CARD_PRODUCT_ID, CARD_TOKEN_ID, CARD_NUMBER_MASKED,
            EXPIRY_DATE, CARD_STATUS, REQUEST_DATE, ISSUE_DATE, CREATED_DATE, CREATED_BY
        ) VALUES (
            v_card_id, p_account_id, p_card_product_id, v_token_id, v_masked,
            p_expiry_date, 'ISSUED', SYSDATE, SYSDATE, SYSDATE, USER
        );

        RETURN v_card_id;
    END issue_card;


    PROCEDURE activate_card (
        p_card_id IN NUMBER
    )
    IS
        v_current_status CM_CARD.CARD_STATUS%TYPE;
    BEGIN
        BEGIN
            SELECT CARD_STATUS INTO v_current_status FROM CM_CARD WHERE CARD_ID = p_card_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                    'activate_card: card ' || p_card_id || ' not found');
        END;

        IF v_current_status != 'ISSUED' THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_invalid_status_num,
                'activate_card: card ' || p_card_id || ' cannot be activated from status ' || v_current_status);
        END IF;

        UPDATE CM_CARD
        SET CARD_STATUS = 'ACTIVE', ACTIVATION_DATE = SYSDATE, UPDATED_DATE = SYSDATE, UPDATED_BY = USER
        WHERE CARD_ID = p_card_id;
    END activate_card;


    PROCEDURE change_card_status (
        p_card_id     IN NUMBER,
        p_new_status  IN VARCHAR2,
        p_reason      IN VARCHAR2 DEFAULT NULL
    )
    IS
        v_current_status CM_CARD.CARD_STATUS%TYPE;
    BEGIN
        BEGIN
            SELECT CARD_STATUS INTO v_current_status FROM CM_CARD WHERE CARD_ID = p_card_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                    'change_card_status: card ' || p_card_id || ' not found');
        END;

        IF v_current_status IN ('CANCELLED','EXPIRED') THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_invalid_status_num,
                'change_card_status: card ' || p_card_id || ' is terminal (' || v_current_status || '), cannot change');
        END IF;

        UPDATE CM_CARD
        SET CARD_STATUS = p_new_status, UPDATED_DATE = SYSDATE, UPDATED_BY = USER
        WHERE CARD_ID = p_card_id;

        -- BLOCK_REASON isn't a column here by design (Epic 0.1 doesn't model it) -
        -- the trigger-driven CM_AUDIT_LOG entry carries the reason via NEW_VALUE instead.
        IF p_reason IS NOT NULL THEN
            PKG_AUDIT_LOG.log_change('CM_CARD', 'UPDATE', TO_CHAR(p_card_id), 'STATUS_CHANGE_REASON', NULL, p_reason);
        END IF;
    END change_card_status;

END PKG_CORE_ENTITY_MGMT;
/
