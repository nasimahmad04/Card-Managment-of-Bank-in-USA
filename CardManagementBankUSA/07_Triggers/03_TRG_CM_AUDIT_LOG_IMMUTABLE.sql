-- ============================================================================
-- Trigger : TRG_CM_AUDIT_LOG_IMMUTABLE
-- Story   : CARD-004 - Implement immutable audit log service
-- Purpose : Enforces "append-only store" at the database level. Blocks UPDATE and
--           DELETE against CM_AUDIT_LOG outright - not even a DBA-privileged app
--           account can silently alter history through normal DML. (A true WORM
--           guarantee in production would pair this with Oracle Database Vault /
--           Flashback Data Archive; this trigger is the baseline DB-level control.)
-- ============================================================================

CREATE OR REPLACE TRIGGER TRG_CM_AUDIT_LOG_IMMUTABLE
BEFORE UPDATE OR DELETE ON CM_AUDIT_LOG
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(
        PKG_CM_EXCEPTIONS.ex_audit_log_immutable_num,
        'CM_AUDIT_LOG is append-only (CARD-004) - UPDATE/DELETE are not permitted on audit records'
    );
END;
/
