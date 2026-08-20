-- ============================================================================
-- Package  : PKG_TOKEN_VAULT (body)
-- Story    : CARD-002
-- Note     : Uses DBMS_CRYPTO for AES-256 encryption at rest, per acceptance criteria
--            "AES-256 encryption at rest verified". The encryption key here is a
--            demo/dev constant for illustration - in a real deployment this MUST come
--            from Oracle Wallet / a KMS (Key Management Service), never hard-coded.
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_TOKEN_VAULT AS

    -- DEV-ONLY placeholder key. Production: pull from Oracle Wallet / external KMS,
    -- rotate per ENCRYPTION_KEY_VERSION, never embed literal key material in source.
    c_encryption_key RAW(32) := UTL_I18N.STRING_TO_RAW('CardMgmtDevKey_ReplaceInProdKMS!', 'AL32UTF8');

    FUNCTION tokenize_pan (
        p_raw_pan IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_pan_hash       VARCHAR2(128);
        v_existing_token NUMBER;
        v_new_token_id   NUMBER;
        v_token_value    VARCHAR2(36);
        v_pan_encrypted  RAW(2000);
    BEGIN
        IF p_raw_pan IS NULL OR LENGTH(p_raw_pan) NOT BETWEEN 12 AND 19
           OR NOT REGEXP_LIKE(p_raw_pan, '^[0-9]+$') THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_invalid_pan_num,
                'tokenize_pan: PAN must be 12-19 numeric digits');
        END IF;

        v_pan_hash := STANDARD_HASH(p_raw_pan, 'SHA256');

        -- Idempotent: if this PAN is already vaulted, return the existing token
        -- rather than raise ex_duplicate_pan - re-tokenizing the same physical card
        -- (e.g. re-issue flow) is a normal, expected path.
        BEGIN
            SELECT TOKEN_ID INTO v_existing_token
            FROM CM_TOKEN_VAULT
            WHERE PAN_HASH = v_pan_hash;
            RETURN v_existing_token;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- proceed to vault it
        END;

        v_pan_encrypted := DBMS_CRYPTO.ENCRYPT(
            src => UTL_I18N.STRING_TO_RAW(p_raw_pan, 'AL32UTF8'),
            typ => DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
            key => c_encryption_key
        );

        v_token_value  := FN_GENERATE_TOKEN;
        v_new_token_id := SEQ_CM_TOKEN_VAULT.NEXTVAL;

        INSERT INTO CM_TOKEN_VAULT (
            TOKEN_ID, TOKEN_VALUE, PAN_ENCRYPTED, PAN_HASH, PAN_LAST4,
            ENCRYPTION_KEY_VERSION, CREATED_DATE, CREATED_BY
        ) VALUES (
            v_new_token_id, v_token_value, v_pan_encrypted, v_pan_hash, SUBSTR(p_raw_pan, -4),
            1, SYSDATE, USER
        );

        RETURN v_new_token_id;
    END tokenize_pan;


    FUNCTION detokenize_pan (
        p_token_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_encrypted RAW(2000);
        v_decrypted RAW(2000);
    BEGIN
        SELECT PAN_ENCRYPTED INTO v_encrypted
        FROM CM_TOKEN_VAULT
        WHERE TOKEN_ID = p_token_id;

        v_decrypted := DBMS_CRYPTO.DECRYPT(
            src => v_encrypted,
            typ => DBMS_CRYPTO.ENCRYPT_AES256 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
            key => c_encryption_key
        );

        RETURN UTL_I18N.RAW_TO_CHAR(v_decrypted, 'AL32UTF8');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                'detokenize_pan: token ' || p_token_id || ' not found in vault');
    END detokenize_pan;


    FUNCTION get_masked_display (
        p_token_id IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_last4 VARCHAR2(4);
    BEGIN
        SELECT PAN_LAST4 INTO v_last4
        FROM CM_TOKEN_VAULT
        WHERE TOKEN_ID = p_token_id;

        RETURN '************' || v_last4;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                'get_masked_display: token ' || p_token_id || ' not found in vault');
    END get_masked_display;

END PKG_TOKEN_VAULT;
/
