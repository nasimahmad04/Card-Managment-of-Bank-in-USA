-- ============================================================================
-- Table   : CM_OFAC_WATCHLIST
-- Story   : CARD-006 - OFAC/sanctions screening service integration
-- Purpose : Local cache of the OFAC SDN (Specially Designated Nationals) list, refreshed
--           from the real OFAC provider feed by an external batch job (out of Epic 0.1
--           scope). Screening runs against this cached table for speed; CARD-006's
--           "real-time" requirement is about response latency to the caller, not
--           necessarily a live external API call per screen.
-- ============================================================================

CREATE TABLE CM_OFAC_WATCHLIST (
    WATCHLIST_ID       NUMBER(10)      NOT NULL,
    FULL_NAME           VARCHAR2(200)  NOT NULL,
    NAME_NORMALIZED       VARCHAR2(200) NOT NULL,  -- upper-cased, punctuation-stripped, for matching
    DATE_OF_BIRTH          DATE         ,
    SDN_TYPE                 VARCHAR2(20) DEFAULT 'INDIVIDUAL', -- INDIVIDUAL | ENTITY | VESSEL
    SOURCE_LIST                VARCHAR2(20) DEFAULT 'OFAC_SDN',
    LOADED_DATE                  DATE   DEFAULT SYSDATE NOT NULL
);

COMMENT ON TABLE CM_OFAC_WATCHLIST IS 'Cached OFAC SDN sanctions list for screening - CARD-006 / [FR-02]';
