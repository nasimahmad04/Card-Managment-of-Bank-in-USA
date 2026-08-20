-- ============================================================================
-- Package  : PKG_CM_EXCEPTIONS (spec)
-- Purpose  : Central registry of custom application exceptions used across every
--            Epic 0.1 package, with consistent error numbers/messages for QA and
--            calling applications to key off.
-- ============================================================================

CREATE OR REPLACE PACKAGE PKG_CM_EXCEPTIONS AS

    -- Error number range reserved for Epic 0.1: -20500 .. -20549

    ex_invalid_pan            EXCEPTION;
    ex_invalid_pan_num        CONSTANT NUMBER := -20500;

    ex_duplicate_pan          EXCEPTION;
    ex_duplicate_pan_num      CONSTANT NUMBER := -20502;

    ex_card_not_found         EXCEPTION;
    ex_card_not_found_num     CONSTANT NUMBER := -20503;

    ex_invalid_status_change  EXCEPTION;
    ex_invalid_status_num     CONSTANT NUMBER := -20504;

    ex_account_not_active     EXCEPTION;
    ex_account_not_active_num CONSTANT NUMBER := -20505;

    ex_product_inactive       EXCEPTION;
    ex_product_inactive_num   CONSTANT NUMBER := -20506;

    ex_underage_applicant     EXCEPTION;
    ex_underage_applicant_num CONSTANT NUMBER := -20507;

    ex_role_not_found         EXCEPTION;
    ex_role_not_found_num     CONSTANT NUMBER := -20508;

    ex_unauthorized_access    EXCEPTION;
    ex_unauthorized_access_num CONSTANT NUMBER := -20509;

    ex_audit_log_immutable    EXCEPTION;
    ex_audit_log_immutable_num CONSTANT NUMBER := -20510;

    ex_ofac_match_blocked     EXCEPTION;
    ex_ofac_match_blocked_num CONSTANT NUMBER := -20511;

    PRAGMA EXCEPTION_INIT (ex_invalid_pan,           -20500);
    PRAGMA EXCEPTION_INIT (ex_duplicate_pan,         -20502);
    PRAGMA EXCEPTION_INIT (ex_card_not_found,        -20503);
    PRAGMA EXCEPTION_INIT (ex_invalid_status_change, -20504);
    PRAGMA EXCEPTION_INIT (ex_account_not_active,    -20505);
    PRAGMA EXCEPTION_INIT (ex_product_inactive,      -20506);
    PRAGMA EXCEPTION_INIT (ex_underage_applicant,    -20507);
    PRAGMA EXCEPTION_INIT (ex_role_not_found,        -20508);
    PRAGMA EXCEPTION_INIT (ex_unauthorized_access,   -20509);
    PRAGMA EXCEPTION_INIT (ex_audit_log_immutable,   -20510);
    PRAGMA EXCEPTION_INIT (ex_ofac_match_blocked,    -20511);

END PKG_CM_EXCEPTIONS;
/
