-- ============================================================================
-- Trigger : TRG_CM_CARD_AUDIT
-- Story   : CARD-004 - Implement immutable audit log service
-- Purpose : Any INSERT/UPDATE/DELETE on CM_CARD writes a before/after audit record.
--           Column-level diffs for UPDATE so reviewers can see exactly what changed
--           (e.g. CARD_STATUS 'ISSUED' -> 'ACTIVE'), not just "a row changed".
-- ============================================================================

CREATE OR REPLACE TRIGGER TRG_CM_CARD_AUDIT
AFTER INSERT OR UPDATE OR DELETE ON CM_CARD
FOR EACH ROW
DECLARE
    v_record_id VARCHAR2(30) := TO_CHAR(NVL(:NEW.CARD_ID, :OLD.CARD_ID));
BEGIN
    IF INSERTING THEN
        PKG_AUDIT_LOG.log_change('CM_CARD', 'INSERT', v_record_id, 'CARD_STATUS', NULL, :NEW.CARD_STATUS);

    ELSIF UPDATING THEN
        IF NVL(:OLD.CARD_STATUS, 'x') != NVL(:NEW.CARD_STATUS, 'x') THEN
            PKG_AUDIT_LOG.log_change('CM_CARD', 'UPDATE', v_record_id, 'CARD_STATUS', :OLD.CARD_STATUS, :NEW.CARD_STATUS);
        END IF;
        IF NVL(:OLD.EXPIRY_DATE, TO_DATE('01011900','DDMMYYYY')) != NVL(:NEW.EXPIRY_DATE, TO_DATE('01011900','DDMMYYYY')) THEN
            PKG_AUDIT_LOG.log_change('CM_CARD', 'UPDATE', v_record_id, 'EXPIRY_DATE',
                TO_CHAR(:OLD.EXPIRY_DATE,'YYYY-MM-DD'), TO_CHAR(:NEW.EXPIRY_DATE,'YYYY-MM-DD'));
        END IF;

    ELSIF DELETING THEN
        PKG_AUDIT_LOG.log_change('CM_CARD', 'DELETE', v_record_id, 'CARD_STATUS', :OLD.CARD_STATUS, NULL);
    END IF;
END;
/
