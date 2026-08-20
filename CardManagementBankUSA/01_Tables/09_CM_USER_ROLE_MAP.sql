-- ============================================================================
-- Table   : CM_USER_ROLE_MAP
-- Story   : CARD-005 - Role-based access control (RBAC) framework
-- Purpose : Maps an application/DB user to exactly one active role at a time.
-- ============================================================================

CREATE TABLE CM_USER_ROLE_MAP (
    USER_ROLE_MAP_ID   NUMBER(10)      NOT NULL,
    APP_USER_ID         VARCHAR2(30)   NOT NULL,   -- application-level user identifier
    ROLE_ID              NUMBER(4)     NOT NULL,
    EFFECTIVE_DATE        DATE         DEFAULT SYSDATE NOT NULL,
    END_DATE               DATE        ,           -- NULL = currently active assignment
    CREATED_DATE            DATE       DEFAULT SYSDATE NOT NULL,
    CREATED_BY              VARCHAR2(30) DEFAULT USER NOT NULL
);

COMMENT ON TABLE CM_USER_ROLE_MAP IS 'Maps application users to RBAC roles - CARD-005';
