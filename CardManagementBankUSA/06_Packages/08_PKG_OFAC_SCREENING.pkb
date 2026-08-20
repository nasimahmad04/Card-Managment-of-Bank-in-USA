-- ============================================================================
-- Package  : PKG_OFAC_SCREENING (body)
-- Story    : CARD-006
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_OFAC_SCREENING AS

    FUNCTION normalize_name(p_name IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN UPPER(REGEXP_REPLACE(TRIM(p_name), '[^A-Za-z ]', ''));
    END normalize_name;


    FUNCTION screen_party (
        p_party_type    IN VARCHAR2,
        p_party_id      IN NUMBER,
        p_full_name     IN VARCHAR2,
        p_date_of_birth IN DATE DEFAULT NULL
    ) RETURN VARCHAR2
    IS
        v_normalized      VARCHAR2(200);
        v_matched_id      NUMBER;
        v_match_score     NUMBER(5,2);
        v_result          VARCHAR2(10);
        v_dob_matches     PLS_INTEGER := 0;
    BEGIN
        IF p_party_type NOT IN ('CUSTOMER','TRANSACTION_PARTY') THEN
            RAISE_APPLICATION_ERROR(-20512, 'screen_party: invalid party_type ' || p_party_type);
        END IF;

        v_normalized := normalize_name(p_full_name);

        BEGIN
            SELECT WATCHLIST_ID,
                   CASE WHEN DATE_OF_BIRTH = p_date_of_birth THEN 100 ELSE 85 END
            INTO v_matched_id, v_match_score
            FROM CM_OFAC_WATCHLIST
            WHERE NAME_NORMALIZED = v_normalized
              AND ROWNUM = 1;

            v_result := CASE WHEN v_match_score = 100 THEN 'MATCH' ELSE 'REVIEW' END;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_matched_id  := NULL;
                v_match_score := 0;
                v_result      := 'NO_MATCH';
        END;

        INSERT INTO CM_OFAC_SCREEN_RESULT (
            SCREEN_RESULT_ID, PARTY_TYPE, PARTY_ID, SCREEN_RESULT,
            MATCHED_WATCHLIST_ID, MATCH_SCORE, SCREENED_DATE, SCREENING_PROVIDER
        ) VALUES (
            SEQ_CM_OFAC_SCREEN_RSLT.NEXTVAL, p_party_type, p_party_id, v_result,
            v_matched_id, v_match_score, SYSTIMESTAMP, 'INTERNAL_OFAC_CACHE'
        );

        RETURN v_result;
    END screen_party;

END PKG_OFAC_SCREENING;
/
