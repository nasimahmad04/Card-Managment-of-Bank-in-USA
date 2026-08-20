-- ============================================================================
-- Package  : PKG_OFAC_SCREENING (spec)
-- Story    : CARD-006 - OFAC/sanctions screening service integration
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_OFAC_SCREENING AS

    -- Screens a name against the cached OFAC watchlist and stores + returns the result.
    -- Simple fuzzy match here (normalized exact + substring); production would call out
    -- to a real OFAC provider API/engine (Fircosoft, LexisNexis, etc.) - this package's
    -- table shape and return contract stay the same either way, only the match logic
    -- inside screen_party swaps out.
    FUNCTION screen_party (
        p_party_type   IN VARCHAR2,     -- CUSTOMER | TRANSACTION_PARTY
        p_party_id     IN NUMBER,
        p_full_name    IN VARCHAR2,
        p_date_of_birth IN DATE DEFAULT NULL
    ) RETURN VARCHAR2;   -- returns MATCH | NO_MATCH | REVIEW

END PKG_OFAC_SCREENING;
/
