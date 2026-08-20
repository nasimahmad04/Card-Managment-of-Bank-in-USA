-- ============================================================================
-- Package  : PKG_RBAC_ACCESS (spec)
-- Story    : CARD-005 - Role-based access control (RBAC) framework
-- Purpose  : The only sanctioned path for anyone to view a card's PAN in any form more
--            revealing than CM_CARD.CARD_NUMBER_MASKED. Resolves the caller's role,
--            applies the correct masking level, and always writes an access-log row -
--            "PAN masked per role, and access is logged" is delivered as one atomic
--            operation, not two things a caller could forget to pair.
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_RBAC_ACCESS AS

    FUNCTION get_masked_pan (
        p_app_user_id IN VARCHAR2,
        p_card_id     IN NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE assign_role (
        p_app_user_id IN VARCHAR2,
        p_role_name   IN VARCHAR2
    );

END PKG_RBAC_ACCESS;
/
