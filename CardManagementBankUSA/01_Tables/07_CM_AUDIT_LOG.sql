-- ============================================================================
-- Table   : CM_AUDIT_LOG
-- Story   : CARD-004 - Implement immutable audit log service
-- Purpose : Append-only audit trail for any state change to Card/Account: who/what/when/
--           before/after, per [FR-71]. Immutability is enforced at the DB level by
--           TRG_CM_AUDIT_LOG_IMMUTABLE (07_Triggers), which blocks UPDATE/DELETE outright -
--           this is not just a convention, the trigger makes it physically true.
-- ============================================================================

CREATE TABLE CM_AUDIT_LOG (
    AUDIT_ID       NUMBER(18)      NOT NULL,
    TABLE_NAME     VARCHAR2(30)    NOT NULL,
    OPERATION      VARCHAR2(10)    NOT NULL,   -- INSERT | UPDATE | DELETE
    RECORD_ID      VARCHAR2(30)    NOT NULL,
    COLUMN_NAME    VARCHAR2(30)    ,           -- populated for column-level UPDATE audit rows
    OLD_VALUE      VARCHAR2(4000)  ,
    NEW_VALUE      VARCHAR2(4000)  ,
    CHANGED_BY     VARCHAR2(30)    DEFAULT USER NOT NULL,
    CHANGED_DATE   TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL
);

COMMENT ON TABLE CM_AUDIT_LOG IS 'Append-only, immutable audit trail (WORM-style) - CARD-004 / [FR-71]. UPDATE and DELETE are blocked at the trigger level, not just by convention.';
