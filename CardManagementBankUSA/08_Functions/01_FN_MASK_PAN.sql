-- ============================================================================
-- Function : FN_MASK_PAN
-- Story    : CARD-002 / CARD-005
-- Purpose  : Pure masking function - given a full PAN and a visibility level, returns
--            the display-safe masked form. Does not touch the vault or do any logging;
--            PKG_RBAC_ACCESS.get_masked_pan() wraps this together with detokenization
--            and access logging.
-- ============================================================================

CREATE OR REPLACE FUNCTION FN_MASK_PAN (
    p_full_pan       IN VARCHAR2,
    p_visibility     IN VARCHAR2 DEFAULT 'MASKED_LAST4'   -- MASKED_LAST4 | MASKED_FIRST6LAST4 | FULL
) RETURN VARCHAR2
IS
    v_len   PLS_INTEGER := LENGTH(p_full_pan);
    v_last4 VARCHAR2(4);
    v_first6 VARCHAR2(6);
BEGIN
    IF p_full_pan IS NULL OR v_len < 12 THEN
        RAISE_APPLICATION_ERROR(-20501, 'FN_MASK_PAN: invalid PAN length');
    END IF;

    v_last4  := SUBSTR(p_full_pan, -4);
    v_first6 := SUBSTR(p_full_pan, 1, 6);

    CASE p_visibility
        WHEN 'FULL' THEN
            RETURN p_full_pan;
        WHEN 'MASKED_FIRST6LAST4' THEN
            RETURN v_first6 || RPAD('*', v_len - 10, '*') || v_last4;
        ELSE -- MASKED_LAST4 (default / safest)
            RETURN RPAD('*', v_len - 4, '*') || v_last4;
    END CASE;
END FN_MASK_PAN;
/
