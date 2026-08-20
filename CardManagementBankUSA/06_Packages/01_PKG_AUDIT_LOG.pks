-- ============================================================================
-- Package  : PKG_AUDIT_LOG (spec)
-- Story    : CARD-004 - Implement immutable audit log service
-- Purpose  : Single entry point triggers call to write an audit row. Keeping this in
--            one package means the audit format is consistent everywhere, and later
--            epics (Account/Card lifecycle changes in Phase 1+) can reuse it.
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_AUDIT_LOG AS

    PROCEDURE log_change (
        p_table_name   IN VARCHAR2,
        p_operation    IN VARCHAR2,      -- INSERT | UPDATE | DELETE
        p_record_id    IN VARCHAR2,
        p_column_name  IN VARCHAR2 DEFAULT NULL,
        p_old_value    IN VARCHAR2 DEFAULT NULL,
        p_new_value    IN VARCHAR2 DEFAULT NULL
    );

END PKG_AUDIT_LOG;
/
