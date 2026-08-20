-- ============================================================================
-- Table   : CM_DATA_ACCESS_LOG
-- Story   : CARD-005 - Role-based access control (RBAC) framework
-- Purpose : "access is logged" - every time cardholder data (PAN) is viewed through
--           PKG_RBAC_ACCESS, a row is written here, regardless of role or masking level.
-- ============================================================================

CREATE TABLE CM_DATA_ACCESS_LOG (
    ACCESS_LOG_ID     NUMBER(18)      NOT NULL,
    APP_USER_ID        VARCHAR2(30)   NOT NULL,
    ROLE_ID             NUMBER(4)     NOT NULL,
    CARD_ID              NUMBER(14)   NOT NULL,
    PAN_VISIBILITY_USED   VARCHAR2(15) NOT NULL,   -- what the user was actually shown
    ACCESS_DATE            TIMESTAMP  DEFAULT SYSTIMESTAMP NOT NULL,
    ACCESS_CHANNEL          VARCHAR2(20) DEFAULT 'INTERNAL_APP'
);

COMMENT ON TABLE CM_DATA_ACCESS_LOG IS 'Every cardholder-data (PAN) view event, per role - CARD-005 access logging requirement';
