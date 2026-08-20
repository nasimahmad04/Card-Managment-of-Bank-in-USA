-- ============================================================================
-- Script  : 02_QA_Scenarios_Epic_0.1.sql
-- Purpose : Automated smoke test for every scenario in
--           01_QA_Scenarios_Epic_0.1.md. Prints PASS/FAIL per scenario.
-- Usage   : Run AFTER 00_Master_Scripts/00_run_all.sql has built the schema.
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

DECLARE
    v_pass_count   PLS_INTEGER := 0;
    v_fail_count   PLS_INTEGER := 0;

    PROCEDURE report(p_scenario IN VARCHAR2, p_passed IN BOOLEAN, p_detail IN VARCHAR2 DEFAULT NULL) IS
    BEGIN
        IF p_passed THEN
            v_pass_count := v_pass_count + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || p_scenario || CASE WHEN p_detail IS NOT NULL THEN ' - ' || p_detail END);
        ELSE
            v_fail_count := v_fail_count + 1;
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_scenario || CASE WHEN p_detail IS NOT NULL THEN ' - ' || p_detail END);
        END IF;
    END report;

    -- shared test fixtures
    v_customer_id     NUMBER;
    v_account_id      NUMBER;
    v_product_debit   NUMBER;
    v_product_credit  NUMBER;
    v_product_prepaid NUMBER;
    v_card_id         NUMBER;
    v_token_id        NUMBER;
    v_result_str      VARCHAR2(4000);
    v_num_result      NUMBER;
    v_count           NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('================ EPIC 0.1 QA SMOKE SUITE ================');

    -- ---------------------------------------------------------------
    -- CARD-001: Core entity schema
    -- ---------------------------------------------------------------
    BEGIN
        v_customer_id := PKG_CORE_ENTITY_MGMT.create_customer(
            'Jane','Doe', DATE '1990-05-15','1234','jane.doe.qa@example.com','2125551234','CONSUMER');
        v_account_id := PKG_CORE_ENTITY_MGMT.open_account(v_customer_id, 'ACCT-QA-0001','DEBIT');
        v_product_debit := PKG_CORE_ENTITY_MGMT.create_card_product('QA-DEBIT-01','QA Debit Card','DEBIT','VISA',1500,18);
        v_card_id := PKG_CORE_ENTITY_MGMT.issue_card(v_account_id, v_product_debit, '4111111111111111', ADD_MONTHS(SYSDATE,48));
        report('1.1 Create customer/account/product/card happy path', v_card_id IS NOT NULL, 'card_id='||v_card_id);
    EXCEPTION WHEN OTHERS THEN report('1.1 Create customer/account/product/card happy path', FALSE, SQLERRM);
    END;

    BEGIN
        v_product_credit  := PKG_CORE_ENTITY_MGMT.create_card_product('QA-CREDIT-01','QA Credit Card','CREDIT','MASTERCARD',5000,21);
        v_product_prepaid := PKG_CORE_ENTITY_MGMT.create_card_product('QA-PREPAID-01','QA Prepaid Card','PREPAID','VISA',500,18);
        report('1.2 product_type discriminator supports DEBIT/CREDIT/PREPAID', TRUE);
    EXCEPTION WHEN OTHERS THEN report('1.2 product_type discriminator supports DEBIT/CREDIT/PREPAID', FALSE, SQLERRM);
    END;

    BEGIN
        INSERT INTO CM_CARD_PRODUCT (CARD_PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE, CARD_NETWORK)
        VALUES (SEQ_CM_CARD_PRODUCT.NEXTVAL, 'QA-BAD-01','Bad Product','CRYPTO','VISA');
        report('1.3 Reject invalid product_type value', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('1.3 Reject invalid product_type value', SQLCODE != 0, SQLERRM);
    END;

    BEGIN
        v_num_result := PKG_CORE_ENTITY_MGMT.issue_card(999999999, v_product_debit, '4222222222222222', SYSDATE);
        report('1.4 Reject card issuance for non-existent account', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('1.4 Reject card issuance for non-existent account', TRUE, SQLERRM);
    END;

    BEGIN
        v_num_result := PKG_CORE_ENTITY_MGMT.open_account(999999999, 'ACCT-BAD','DEBIT');
        report('1.5 Reject account open for non-existent customer', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('1.5 Reject account open for non-existent customer', TRUE, SQLERRM);
    END;

    BEGIN
        v_num_result := PKG_CORE_ENTITY_MGMT.create_customer('John','Smith', DATE '1985-01-01','5678','jane.doe.qa@example.com','2125559999');
        report('1.6 Reject duplicate customer email', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('1.6 Reject duplicate customer email', TRUE, SQLERRM);
    END;

    -- ---------------------------------------------------------------
    -- CARD-002: PAN tokenization/vaulting
    -- ---------------------------------------------------------------
    BEGIN
        v_token_id := PKG_TOKEN_VAULT.tokenize_pan('4333333333333333');
        SELECT PAN_LAST4 INTO v_result_str FROM CM_TOKEN_VAULT WHERE TOKEN_ID = v_token_id;
        report('2.1 Tokenize valid PAN', v_result_str = '3333', 'last4='||v_result_str);
    EXCEPTION WHEN OTHERS THEN report('2.1 Tokenize valid PAN', FALSE, SQLERRM);
    END;

    BEGIN
        SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS
        WHERE TABLE_NAME = 'CM_CARD' AND COLUMN_NAME IN ('CARD_NUMBER','PAN','CARD_NUMBER_FULL','PAN_NUMBER');
        report('2.2 CM_CARD has no raw-PAN-capable column', v_count = 0, 'matching columns found='||v_count);
    EXCEPTION WHEN OTHERS THEN report('2.2 CM_CARD has no raw-PAN-capable column', FALSE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_TOKEN_VAULT.detokenize_pan(v_token_id);
        report('2.3 Detokenize round-trip matches original PAN', v_result_str = '4333333333333333', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('2.3 Detokenize round-trip matches original PAN', FALSE, SQLERRM);
    END;

    BEGIN
        v_num_result := PKG_TOKEN_VAULT.tokenize_pan('4333333333333333'); -- same PAN again
        report('2.4 Re-tokenizing same PAN is idempotent', v_num_result = v_token_id, 'token='||v_num_result||' expected='||v_token_id);
    EXCEPTION WHEN OTHERS THEN report('2.4 Re-tokenizing same PAN is idempotent', FALSE, SQLERRM);
    END;

    BEGIN
        v_num_result := PKG_TOKEN_VAULT.tokenize_pan('ABCD1234');
        report('2.5 Reject non-numeric PAN', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('2.5 Reject non-numeric PAN', TRUE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_TOKEN_VAULT.detokenize_pan(999999999);
        report('2.6 Reject detokenize on unknown token_id', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('2.6 Reject detokenize on unknown token_id', TRUE, SQLERRM);
    END;

    BEGIN
        UPDATE CM_CARD SET CARD_TOKEN_ID = v_token_id WHERE CARD_ID = v_card_id;
        report('2.7 Reject re-pointing CARD_TOKEN_ID after issuance', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('2.7 Reject re-pointing CARD_TOKEN_ID after issuance', TRUE, SQLERRM);
    END;
    ROLLBACK; -- undo any partial effect of the 2.7 attempt

    -- ---------------------------------------------------------------
    -- CARD-003: CDE asset scope register
    -- ---------------------------------------------------------------
    BEGIN
        SELECT COUNT(*) INTO v_count FROM CM_CDE_ASSET_SCOPE WHERE IN_CDE_SCOPE = 'Y';
        report('3.1 CDE-scoped objects are registered', v_count >= 2, 'rows='||v_count);
    EXCEPTION WHEN OTHERS THEN report('3.1 CDE-scoped objects are registered', FALSE, SQLERRM);
    END;

    BEGIN
        SELECT COUNT(*) INTO v_count FROM CM_CDE_ASSET_SCOPE WHERE OBJECT_NAME = 'CM_CARD' AND IN_CDE_SCOPE = 'N';
        report('3.2 CM_CARD explicitly registered out-of-scope', v_count = 1, 'rows='||v_count);
    EXCEPTION WHEN OTHERS THEN report('3.2 CM_CARD explicitly registered out-of-scope', FALSE, SQLERRM);
    END;

    -- ---------------------------------------------------------------
    -- CARD-004: Immutable audit log
    -- ---------------------------------------------------------------
    BEGIN
        PKG_CORE_ENTITY_MGMT.activate_card(v_card_id);
        SELECT COUNT(*) INTO v_count FROM CM_AUDIT_LOG
        WHERE TABLE_NAME = 'CM_CARD' AND RECORD_ID = TO_CHAR(v_card_id) AND COLUMN_NAME = 'CARD_STATUS';
        report('4.1 Card status change writes audit trail (INSERT + UPDATE)', v_count >= 2, 'audit rows='||v_count);
    EXCEPTION WHEN OTHERS THEN report('4.1 Card status change writes audit trail (INSERT + UPDATE)', FALSE, SQLERRM);
    END;

    BEGIN
        UPDATE CM_ACCOUNT SET CURRENT_BALANCE = 100 WHERE ACCOUNT_ID = v_account_id;
        SELECT COUNT(*) INTO v_count FROM CM_AUDIT_LOG WHERE TABLE_NAME = 'CM_ACCOUNT' AND RECORD_ID = TO_CHAR(v_account_id);
        report('4.2 Account balance change writes audit trail automatically', v_count >= 1, 'audit rows='||v_count);
    EXCEPTION WHEN OTHERS THEN report('4.2 Account balance change writes audit trail automatically', FALSE, SQLERRM);
    END;

    BEGIN
        SELECT AUDIT_ID INTO v_num_result FROM CM_AUDIT_LOG WHERE ROWNUM = 1;
        UPDATE CM_AUDIT_LOG SET NEW_VALUE = 'TAMPERED' WHERE AUDIT_ID = v_num_result;
        report('4.3 Reject UPDATE on CM_AUDIT_LOG', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('4.3 Reject UPDATE on CM_AUDIT_LOG', TRUE, SQLERRM);
    END;

    BEGIN
        SELECT AUDIT_ID INTO v_num_result FROM CM_AUDIT_LOG WHERE ROWNUM = 1;
        DELETE FROM CM_AUDIT_LOG WHERE AUDIT_ID = v_num_result;
        report('4.4 Reject DELETE on CM_AUDIT_LOG', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('4.4 Reject DELETE on CM_AUDIT_LOG', TRUE, SQLERRM);
    END;

    -- ---------------------------------------------------------------
    -- CARD-005: RBAC framework
    -- ---------------------------------------------------------------
    BEGIN
        PKG_RBAC_ACCESS.assign_role('QA_USER_AGENT','AGENT');
        v_result_str := PKG_RBAC_ACCESS.get_masked_pan('QA_USER_AGENT', v_card_id);
        report('5.1 AGENT role sees only last-4 PAN', v_result_str LIKE '%3333' AND LENGTH(v_result_str) < 17, v_result_str);
    EXCEPTION WHEN OTHERS THEN report('5.1 AGENT role sees only last-4 PAN', FALSE, SQLERRM);
    END;

    BEGIN
        PKG_RBAC_ACCESS.assign_role('QA_USER_ANALYST','ANALYST');
        v_result_str := PKG_RBAC_ACCESS.get_masked_pan('QA_USER_ANALYST', v_card_id);
        report('5.2 ANALYST role sees first-6+last-4 PAN', v_result_str LIKE '433333%3333', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('5.2 ANALYST role sees first-6+last-4 PAN', FALSE, SQLERRM);
    END;

    BEGIN
        PKG_RBAC_ACCESS.assign_role('QA_USER_COMPLIANCE','COMPLIANCE');
        v_result_str := PKG_RBAC_ACCESS.get_masked_pan('QA_USER_COMPLIANCE', v_card_id);
        report('5.3 COMPLIANCE role sees full PAN', v_result_str = '4333333333333333', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('5.3 COMPLIANCE role sees full PAN', FALSE, SQLERRM);
    END;

    BEGIN
        SELECT COUNT(*) INTO v_count FROM CM_DATA_ACCESS_LOG WHERE CARD_ID = v_card_id AND APP_USER_ID LIKE 'QA_USER_%';
        report('5.4 Every PAN view is logged regardless of role', v_count = 3, 'log rows='||v_count);
    EXCEPTION WHEN OTHERS THEN report('5.4 Every PAN view is logged regardless of role', FALSE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_RBAC_ACCESS.get_masked_pan('QA_USER_NO_ROLE', v_card_id);
        report('5.5 Reject access for user with no role assigned', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('5.5 Reject access for user with no role assigned', TRUE, SQLERRM);
    END;

    BEGIN
        PKG_RBAC_ACCESS.assign_role('QA_USER_AGENT','COMPLIANCE'); -- re-assign
        SELECT COUNT(*) INTO v_count FROM CM_USER_ROLE_MAP WHERE APP_USER_ID = 'QA_USER_AGENT' AND END_DATE IS NULL;
        report('5.6 Exactly one active role mapping after re-assignment', v_count = 1, 'active mappings='||v_count);
    EXCEPTION WHEN OTHERS THEN report('5.6 Exactly one active role mapping after re-assignment', FALSE, SQLERRM);
    END;

    BEGIN
        INSERT INTO CM_ROLE (ROLE_ID, ROLE_NAME, PAN_VISIBILITY) VALUES (99,'AGENT','ALWAYS_SHOW');
        report('5.7 Reject invalid PAN_VISIBILITY value', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('5.7 Reject invalid PAN_VISIBILITY value', TRUE, SQLERRM);
    END;

    -- ---------------------------------------------------------------
    -- CARD-006: OFAC/sanctions screening
    -- ---------------------------------------------------------------
    BEGIN
        INSERT INTO CM_OFAC_WATCHLIST (WATCHLIST_ID, FULL_NAME, NAME_NORMALIZED, DATE_OF_BIRTH)
        VALUES (SEQ_CM_OFAC_WATCHLIST.NEXTVAL, 'Suspect Person', 'SUSPECT PERSON', DATE '1970-01-01');

        v_result_str := PKG_OFAC_SCREENING.screen_party('CUSTOMER', v_customer_id, 'Jane Doe', DATE '1990-05-15');
        report('6.1 Unrelated name screens NO_MATCH', v_result_str = 'NO_MATCH', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('6.1 Unrelated name screens NO_MATCH', FALSE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_OFAC_SCREENING.screen_party('CUSTOMER', 8888, 'Suspect Person', DATE '1970-01-01');
        report('6.2 Exact name+DOB match screens MATCH', v_result_str = 'MATCH', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('6.2 Exact name+DOB match screens MATCH', FALSE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_OFAC_SCREENING.screen_party('CUSTOMER', 8889, 'Suspect Person', DATE '1985-06-15');
        report('6.3 Name match, DOB mismatch screens REVIEW', v_result_str = 'REVIEW', v_result_str);
    EXCEPTION WHEN OTHERS THEN report('6.3 Name match, DOB mismatch screens REVIEW', FALSE, SQLERRM);
    END;

    BEGIN
        v_result_str := PKG_OFAC_SCREENING.screen_party('VENDOR', 1, 'Nobody', NULL);
        report('6.5 Reject invalid party_type', FALSE, 'expected exception, none raised');
    EXCEPTION WHEN OTHERS THEN report('6.5 Reject invalid party_type', TRUE, SQLERRM);
    END;

    -- ---------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('===========================================================');
    DBMS_OUTPUT.PUT_LINE('RESULT: ' || v_pass_count || ' PASSED, ' || v_fail_count || ' FAILED');
    DBMS_OUTPUT.PUT_LINE('===========================================================');

    COMMIT;
END;
/
