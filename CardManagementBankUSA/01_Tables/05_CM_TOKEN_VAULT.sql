-- ============================================================================
-- Table   : CM_TOKEN_VAULT
-- Story   : CARD-002 - Implement PAN tokenization/vaulting service
-- Purpose : The ONLY table in the schema permitted to hold PAN data, and even here it is
--           never stored in plain text - only AES-256 encrypted (via DBMS_CRYPTO) bytes,
--           plus a one-way hash used for lookups/uniqueness checks. Conceptually this
--           table should live in its own PCI-scoped schema (separate from the rest of
--           the app schema) with grants restricted to PKG_TOKEN_VAULT only - see
--           03_Constraints / grants note.
-- ============================================================================

CREATE TABLE CM_TOKEN_VAULT (
    TOKEN_ID            NUMBER(18)      NOT NULL,
    TOKEN_VALUE          VARCHAR2(36)   NOT NULL,   -- surrogate token (GUID-like) exposed to other tables
    PAN_ENCRYPTED         RAW(2000)     NOT NULL,   -- AES-256 encrypted PAN bytes - never plain text
    PAN_HASH               VARCHAR2(128) NOT NULL,   -- SHA-256 hash of PAN, for uniqueness/lookup without decrypting
    PAN_LAST4               VARCHAR2(4) NOT NULL,   -- last 4 digits only, safe to keep unencrypted for display
    ENCRYPTION_KEY_VERSION NUMBER(4)    DEFAULT 1 NOT NULL,
    CREATED_DATE           DATE         DEFAULT SYSDATE NOT NULL,
    CREATED_BY             VARCHAR2(30) DEFAULT USER NOT NULL
);

COMMENT ON TABLE  CM_TOKEN_VAULT IS 'PCI-scoped PAN vault - CARD-002. Raw PAN never persists in plain text anywhere, including here.';
COMMENT ON COLUMN CM_TOKEN_VAULT.TOKEN_VALUE      IS 'Surrogate token referenced by CM_CARD.CARD_TOKEN_ID - safe to pass around the rest of the app';
COMMENT ON COLUMN CM_TOKEN_VAULT.PAN_ENCRYPTED    IS 'AES-256 (DBMS_CRYPTO) encrypted PAN bytes at rest';
COMMENT ON COLUMN CM_TOKEN_VAULT.PAN_HASH         IS 'SHA-256 hash of PAN - allows duplicate-PAN detection without decrypting';

-- Recommended (documented, not executed here - requires DBA):
--   REVOKE ALL ON CM_TOKEN_VAULT FROM PUBLIC;
--   GRANT SELECT, INSERT ON CM_TOKEN_VAULT TO ROLE_TOKEN_VAULT_SVC;  -- only PKG_TOKEN_VAULT's invoker
--   In production this table lives in a physically separate PCI-scoped schema/pluggable DB.
