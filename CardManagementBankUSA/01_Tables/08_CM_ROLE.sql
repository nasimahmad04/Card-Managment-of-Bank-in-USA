-- ============================================================================
-- Table   : CM_ROLE
-- Story   : CARD-005 - Role-based access control (RBAC) framework
-- Purpose : The 4 roles named explicitly in the acceptance criteria: Agent, Analyst,
--           Admin, Compliance. PAN visibility level drives how much of the PAN
--           PKG_RBAC_ACCESS.get_masked_pan() reveals to that role.
-- ============================================================================

CREATE TABLE CM_ROLE (
    ROLE_ID            NUMBER(4)       NOT NULL,
    ROLE_NAME          VARCHAR2(20)    NOT NULL,   -- AGENT | ANALYST | ADMIN | COMPLIANCE
    PAN_VISIBILITY      VARCHAR2(15)   NOT NULL,   -- MASKED_LAST4 | MASKED_FIRST6LAST4 | FULL
    DESCRIPTION         VARCHAR2(200)  ,
    CREATED_DATE         DATE          DEFAULT SYSDATE NOT NULL
);

COMMENT ON TABLE  CM_ROLE IS 'RBAC role catalog - CARD-005. Agent/Analyst/Admin/Compliance per acceptance criteria.';
COMMENT ON COLUMN CM_ROLE.PAN_VISIBILITY IS 'MASKED_LAST4 (default/Agent) | MASKED_FIRST6LAST4 (Analyst) | FULL (Compliance, always logged)';

-- Seed the 4 roles named in the story
INSERT INTO CM_ROLE (ROLE_ID, ROLE_NAME, PAN_VISIBILITY, DESCRIPTION) VALUES (1, 'AGENT',      'MASKED_LAST4',        'Front-line customer service - sees last 4 digits only');
INSERT INTO CM_ROLE (ROLE_ID, ROLE_NAME, PAN_VISIBILITY, DESCRIPTION) VALUES (2, 'ANALYST',    'MASKED_FIRST6LAST4',  'Fraud/risk analyst - sees BIN + last 4 for pattern analysis');
INSERT INTO CM_ROLE (ROLE_ID, ROLE_NAME, PAN_VISIBILITY, DESCRIPTION) VALUES (3, 'ADMIN',      'MASKED_LAST4',        'System administrator - operational access, not cardholder-data access');
INSERT INTO CM_ROLE (ROLE_ID, ROLE_NAME, PAN_VISIBILITY, DESCRIPTION) VALUES (4, 'COMPLIANCE', 'FULL',                'Compliance officer - full PAN access, every view is logged to CM_DATA_ACCESS_LOG');
