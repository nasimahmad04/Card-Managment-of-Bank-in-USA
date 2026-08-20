-- ============================================================================
-- Script  : 00_run_all.sql
-- Purpose : Runs every Epic 0.1 object in correct dependency order.
-- Usage   : Run from SQL Developer / SQL*Plus with this file's directory as CWD, e.g.
--             sqlplus user/pass@db @00_run_all.sql
--           Assumes DBMS_CRYPTO privileges are already granted to the schema owner:
--             GRANT EXECUTE ON DBMS_CRYPTO TO <schema_owner>;
-- ============================================================================

SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
WHENEVER SQLERROR CONTINUE

PROMPT ===== 1. TABLES =====
@@../01_Tables/01_CM_CUSTOMER.sql
@@../01_Tables/02_CM_ACCOUNT.sql
@@../01_Tables/03_CM_CARD_PRODUCT.sql
@@../01_Tables/04_CM_CARD.sql
@@../01_Tables/05_CM_TOKEN_VAULT.sql
@@../01_Tables/06_CM_CDE_ASSET_SCOPE.sql
@@../01_Tables/07_CM_AUDIT_LOG.sql
@@../01_Tables/08_CM_ROLE.sql
@@../01_Tables/09_CM_USER_ROLE_MAP.sql
@@../01_Tables/10_CM_DATA_ACCESS_LOG.sql
@@../01_Tables/11_CM_OFAC_WATCHLIST.sql
@@../01_Tables/12_CM_OFAC_SCREEN_RESULT.sql

PROMPT ===== 2. SEQUENCES =====
@@../02_Sequences/01_all_sequences.sql

PROMPT ===== 3. CONSTRAINTS =====
@@../03_Constraints/01_primary_keys.sql
@@../03_Constraints/02_foreign_keys.sql
@@../03_Constraints/03_unique_keys.sql
@@../03_Constraints/04_check_constraints.sql

PROMPT ===== 4. INDEXES =====
@@../04_Indexes/01_indexes.sql

PROMPT ===== 5. FUNCTIONS (no dependencies on packages) =====
@@../08_Functions/01_FN_MASK_PAN.sql
@@../08_Functions/02_FN_GENERATE_TOKEN.sql

PROMPT ===== 6. EXCEPTION REGISTRY =====
@@../09_Procedures/01_PKG_CM_EXCEPTIONS.pks

PROMPT ===== 7. PACKAGES (spec then body, in dependency order) =====
@@../06_Packages/01_PKG_AUDIT_LOG.pks
@@../06_Packages/02_PKG_AUDIT_LOG.pkb
@@../06_Packages/03_PKG_TOKEN_VAULT.pks
@@../06_Packages/04_PKG_TOKEN_VAULT.pkb
@@../06_Packages/05_PKG_RBAC_ACCESS.pks
@@../06_Packages/06_PKG_RBAC_ACCESS.pkb
@@../06_Packages/07_PKG_OFAC_SCREENING.pks
@@../06_Packages/08_PKG_OFAC_SCREENING.pkb
@@../06_Packages/09_PKG_CORE_ENTITY_MGMT.pks
@@../06_Packages/10_PKG_CORE_ENTITY_MGMT.pkb

PROMPT ===== 8. VIEWS =====
@@../05_Views/01_VW_CARD_SUMMARY.sql

PROMPT ===== 9. TRIGGERS (depend on packages above) =====
@@../07_Triggers/01_TRG_CM_CARD_AUDIT.sql
@@../07_Triggers/02_TRG_CM_ACCOUNT_AUDIT.sql
@@../07_Triggers/03_TRG_CM_AUDIT_LOG_IMMUTABLE.sql
@@../07_Triggers/04_TRG_CM_CARD_TOKEN_READONLY.sql

PROMPT ===== EPIC 0.1 BUILD COMPLETE =====
PROMPT Run 10_QA_Test_Scripts/01_QA_Scenarios_Epic_0.1.sql next to validate.

-- Report any invalid objects left behind
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE STATUS != 'VALID'
ORDER BY OBJECT_TYPE, OBJECT_NAME;
