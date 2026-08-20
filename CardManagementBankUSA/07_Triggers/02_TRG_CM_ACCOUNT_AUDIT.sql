-- ============================================================================
-- Trigger : TRG_CM_ACCOUNT_AUDIT
-- Story   : CARD-004 - Implement immutable audit log service
-- Purpose : Any INSERT/UPDATE/DELETE on CM_ACCOUNT writes a before/after audit record,
--           per acceptance criteria "any state change to Card/Account".
-- ============================================================================

CREATE OR REPLACE TRIGGER TRG_CM_ACCOUNT_AUDIT
AFTER INSERT OR UPDATE OR DELETE ON CM_ACCOUNT
FOR EACH ROW
DECLARE
    v_record_id VARCHAR2(30) := TO_CHAR(NVL(:NEW.ACCOUNT_ID, :OLD.ACCOUNT_ID));
BEGIN
    IF INSERTING THEN
        PKG_AUDIT_LOG.log_change('CM_ACCOUNT', 'INSERT', v_record_id, 'ACCOUNT_STATUS', NULL, :NEW.ACCOUNT_STATUS);

    ELSIF UPDATING THEN
        IF NVL(:OLD.ACCOUNT_STATUS,'x') != NVL(:NEW.ACCOUNT_STATUS,'x') THEN
            PKG_AUDIT_LOG.log_change('CM_ACCOUNT', 'UPDATE', v_record_id, 'ACCOUNT_STATUS', :OLD.ACCOUNT_STATUS, :NEW.ACCOUNT_STATUS);
        END IF;
        IF NVL(:OLD.CURRENT_BALANCE,-1) != NVL(:NEW.CURRENT_BALANCE,-1) THEN
            PKG_AUDIT_LOG.log_change('CM_ACCOUNT', 'UPDATE', v_record_id, 'CURRENT_BALANCE',
                TO_CHAR(:OLD.CURRENT_BALANCE), TO_CHAR(:NEW.CURRENT_BALANCE));
        END IF;

    ELSIF DELETING THEN
        PKG_AUDIT_LOG.log_change('CM_ACCOUNT', 'DELETE', v_record_id, 'ACCOUNT_STATUS', :OLD.ACCOUNT_STATUS, NULL);
    END IF;
END;
/
