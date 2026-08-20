-- ============================================================================
-- Trigger : TRG_CM_CARD_TOKEN_READONLY
-- Story   : CARD-002 - Implement PAN tokenization/vaulting service
-- Purpose : A card's CARD_TOKEN_ID must never be repointed to a different vault entry
--           after issuance (that would let one card's audit/status history silently
--           apply to a different PAN). Blocks any UPDATE that changes CARD_TOKEN_ID.
-- ============================================================================

CREATE OR REPLACE TRIGGER TRG_CM_CARD_TOKEN_READONLY
BEFORE UPDATE OF CARD_TOKEN_ID ON CM_CARD
FOR EACH ROW
BEGIN
    IF :OLD.CARD_TOKEN_ID != :NEW.CARD_TOKEN_ID THEN
        RAISE_APPLICATION_ERROR(-20513,
            'CM_CARD.CARD_TOKEN_ID is immutable once set (CARD-002) - a card cannot be re-pointed to a different vaulted PAN');
    END IF;
END;
/
