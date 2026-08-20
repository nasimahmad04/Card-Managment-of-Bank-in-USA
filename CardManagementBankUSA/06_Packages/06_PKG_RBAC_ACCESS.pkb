-- ============================================================================
-- Package  : PKG_RBAC_ACCESS (body)
-- Story    : CARD-005
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_RBAC_ACCESS AS

    FUNCTION get_masked_pan (
        p_app_user_id IN VARCHAR2,
        p_card_id     IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_role_id        CM_ROLE.ROLE_ID%TYPE;
        v_pan_visibility CM_ROLE.PAN_VISIBILITY%TYPE;
        v_token_id       CM_CARD.CARD_TOKEN_ID%TYPE;
        v_full_pan       VARCHAR2(19);
        v_result         VARCHAR2(19);
    BEGIN
        -- Resolve the caller's current active role
        BEGIN
            SELECT r.ROLE_ID, r.PAN_VISIBILITY
            INTO v_role_id, v_pan_visibility
            FROM CM_USER_ROLE_MAP urm
            JOIN CM_ROLE r ON r.ROLE_ID = urm.ROLE_ID
            WHERE urm.APP_USER_ID = p_app_user_id
              AND urm.END_DATE IS NULL
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_role_not_found_num,
                    'get_masked_pan: no active role assigned for user ' || p_app_user_id);
        END;

        SELECT CARD_TOKEN_ID INTO v_token_id
        FROM CM_CARD
        WHERE CARD_ID = p_card_id;

        IF v_pan_visibility = 'FULL' THEN
            v_full_pan := PKG_TOKEN_VAULT.detokenize_pan(v_token_id);
            v_result   := FN_MASK_PAN(v_full_pan, 'FULL');
        ELSIF v_pan_visibility = 'MASKED_FIRST6LAST4' THEN
            v_full_pan := PKG_TOKEN_VAULT.detokenize_pan(v_token_id);
            v_result   := FN_MASK_PAN(v_full_pan, 'MASKED_FIRST6LAST4');
        ELSE
            v_result := PKG_TOKEN_VAULT.get_masked_display(v_token_id);
        END IF;

        -- "access is logged" - every view, every role, no exceptions
        INSERT INTO CM_DATA_ACCESS_LOG (
            ACCESS_LOG_ID, APP_USER_ID, ROLE_ID, CARD_ID, PAN_VISIBILITY_USED, ACCESS_DATE
        ) VALUES (
            SEQ_CM_DATA_ACCESS_LOG.NEXTVAL, p_app_user_id, v_role_id, p_card_id, v_pan_visibility, SYSTIMESTAMP
        );

        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_card_not_found_num,
                'get_masked_pan: card ' || p_card_id || ' not found');
    END get_masked_pan;


    PROCEDURE assign_role (
        p_app_user_id IN VARCHAR2,
        p_role_name   IN VARCHAR2
    )
    IS
        v_role_id CM_ROLE.ROLE_ID%TYPE;
    BEGIN
        BEGIN
            SELECT ROLE_ID INTO v_role_id FROM CM_ROLE WHERE ROLE_NAME = UPPER(p_role_name);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(PKG_CM_EXCEPTIONS.ex_role_not_found_num,
                    'assign_role: role ' || p_role_name || ' does not exist');
        END;

        -- End-date any currently active assignment first (one active role per user)
        UPDATE CM_USER_ROLE_MAP
        SET END_DATE = SYSDATE
        WHERE APP_USER_ID = p_app_user_id
          AND END_DATE IS NULL;

        INSERT INTO CM_USER_ROLE_MAP (
            USER_ROLE_MAP_ID, APP_USER_ID, ROLE_ID, EFFECTIVE_DATE, CREATED_DATE, CREATED_BY
        ) VALUES (
            SEQ_CM_USER_ROLE_MAP.NEXTVAL, p_app_user_id, v_role_id, SYSDATE, SYSDATE, USER
        );
    END assign_role;

END PKG_RBAC_ACCESS;
/
