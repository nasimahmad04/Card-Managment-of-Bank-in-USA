-- ============================================================================
-- Table   : CM_CARD
-- Story   : CARD-001 - Design core entity schema
--           CARD-002 - PAN tokenization/vaulting service (enforced structurally here)
-- Purpose : Master card record. Deliberately has NO plain-text PAN column - only a
--           CARD_TOKEN_ID pointing into the PCI-scoped CM_TOKEN_VAULT, plus a cached
--           display-safe masked PAN. There is no column in this table a raw PAN could
--           ever be written to.
-- ============================================================================

CREATE TABLE CM_CARD (
    CARD_ID             NUMBER(14)      NOT NULL,
    ACCOUNT_ID           NUMBER(14)     NOT NULL,
    CARD_PRODUCT_ID      NUMBER(6)      NOT NULL,
    CARD_TOKEN_ID        NUMBER(18)     NOT NULL,   -- FK -> CM_TOKEN_VAULT surrogate token (CARD-002)
    CARD_NUMBER_MASKED   VARCHAR2(19)   NOT NULL,   -- cached display value e.g. 4111********1111
    EXPIRY_DATE          DATE           ,
    CARD_STATUS          VARCHAR2(15)   DEFAULT 'REQUESTED' NOT NULL,
    REQUEST_DATE         DATE           DEFAULT SYSDATE NOT NULL,
    ISSUE_DATE           DATE           ,
    ACTIVATION_DATE      DATE           ,
    CREATED_DATE         DATE           DEFAULT SYSDATE NOT NULL,
    CREATED_BY           VARCHAR2(30)   DEFAULT USER NOT NULL,
    UPDATED_DATE         DATE           ,
    UPDATED_BY           VARCHAR2(30)
);

COMMENT ON TABLE  CM_CARD IS 'Master card record - CARD-001. No raw PAN column exists here by design (CARD-002); only a token reference + masked display value.';
COMMENT ON COLUMN CM_CARD.CARD_TOKEN_ID      IS 'FK to CM_TOKEN_VAULT - the ONLY place the real PAN (encrypted) lives';
COMMENT ON COLUMN CM_CARD.CARD_NUMBER_MASKED IS 'Cached masked PAN for UI display, e.g. 4111********1111 - never the full number';
COMMENT ON COLUMN CM_CARD.CARD_STATUS        IS 'REQUESTED | ISSUED | ACTIVE | BLOCKED | CANCELLED | EXPIRED';
