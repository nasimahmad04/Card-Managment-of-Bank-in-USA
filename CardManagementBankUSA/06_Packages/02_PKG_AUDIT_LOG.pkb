-- ============================================================================
-- Package  : PKG_AUDIT_LOG (body)
-- Story    : CARD-004
-- Note     : Uses autonomous transaction so the audit write commits independently
--            of the caller's transaction - an audit record should exist even if the
--            triggering DML later rolls back for an unrelated reason within the same
--            session, and it decouples audit-log writes from the caller's commit point.
-- ============================================================================

CREATE OR REPLACE PACKAGE BODY PKG_AUDIT_LOG AS

    PROCEDURE log_change (
        p_table_name   IN VARCHAR2,
        p_operation    IN VARCHAR2,
        p_record_id    IN VARCHAR2,
        p_column_name  IN VARCHAR2 DEFAULT NULL,
        p_old_value    IN VARCHAR2 DEFAULT NULL,
        p_new_value    IN VARCHAR2 DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO CM_AUDIT_LOG (
            AUDIT_ID, TABLE_NAME, OPERATION, RECORD_ID,
            COLUMN_NAME, OLD_VALUE, NEW_VALUE, CHANGED_BY, CHANGED_DATE
        ) VALUES (
            SEQ_CM_AUDIT_LOG.NEXTVAL, p_table_name, p_operation, p_record_id,
            p_column_name, p_old_value, p_new_value, USER, SYSTIMESTAMP
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            -- Audit logging must never silently swallow errors and must never block
            -- the primary transaction either; re-raise so callers/DBAs are aware.
            RAISE_APPLICATION_ERROR(-20520, 'PKG_AUDIT_LOG.log_change failed: ' || SQLERRM);
    END log_change;

END PKG_AUDIT_LOG;
/
