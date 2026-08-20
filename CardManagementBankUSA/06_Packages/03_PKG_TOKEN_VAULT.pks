-- ============================================================================
-- Package  : PKG_TOKEN_VAULT (spec)
-- Story    : CARD-002 - Implement PAN tokenization/vaulting service
-- Purpose  : The ONLY package permitted to encrypt/decrypt PAN data. Everything else
--            in the schema (including PKG_CARD_ISSUANCE) calls tokenize_pan() and gets
--            back a surrogate token - it never sees or handles the raw PAN itself
--            beyond the single call boundary.
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_TOKEN_VAULT AS

    -- Encrypts and vaults a raw PAN, returns the new (or existing, if PAN already
    -- vaulted) TOKEN_ID. Raises PKG_CM_EXCEPTIONS.ex_invalid_pan for bad input.
    FUNCTION tokenize_pan (
        p_raw_pan IN VARCHAR2
    ) RETURN NUMBER;

    -- Detokenizes back to the full raw PAN. Restricted by design: only
    -- PKG_RBAC_ACCESS should ever call this, and only for COMPLIANCE-role requests,
    -- with the call itself logged there. This function does not check role -
    -- authorization is the caller's job by architecture (documented, enforced by grants
    -- in a real deployment).
    FUNCTION detokenize_pan (
        p_token_id IN NUMBER
    ) RETURN VARCHAR2;

    -- Returns just the cached masked-display value for a token, safe for anyone to call.
    FUNCTION get_masked_display (
        p_token_id IN NUMBER
    ) RETURN VARCHAR2;

END PKG_TOKEN_VAULT;
/
