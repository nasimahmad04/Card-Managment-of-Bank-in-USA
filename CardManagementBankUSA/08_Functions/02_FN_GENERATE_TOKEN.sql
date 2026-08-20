-- ============================================================================
-- Function : FN_GENERATE_TOKEN
-- Story    : CARD-002 - Implement PAN tokenization/vaulting service
-- Purpose  : Generates a non-reversible, non-sequential surrogate token value (GUID-
--            style) that other tables can safely reference in place of a PAN.
-- ============================================================================

CREATE OR REPLACE FUNCTION FN_GENERATE_TOKEN
RETURN VARCHAR2
IS
BEGIN
    RETURN RAWTOHEX(SYS_GUID());   -- 32-char hex GUID, non-sequential, safe surrogate
END FN_GENERATE_TOKEN;
/
