-- ============================================================================
-- Table   : CM_CDE_ASSET_SCOPE
-- Story   : CARD-003 - Establish PCI DSS CDE network segmentation
-- Purpose : CARD-003 is fundamentally infrastructure work (VLAN/VPC segmentation) and is
--           NOT implemented by DDL/PLSQL. This table exists only to satisfy the
--           "documented access control list" part of the acceptance criteria - a
--           queryable register of which DB objects/services sit inside the Cardholder
--           Data Environment (CDE) boundary, for audit evidence.
-- ============================================================================

CREATE TABLE CM_CDE_ASSET_SCOPE (
    ASSET_SCOPE_ID     NUMBER(6)       NOT NULL,
    OBJECT_NAME        VARCHAR2(60)    NOT NULL,
    OBJECT_TYPE        VARCHAR2(20)    NOT NULL,   -- TABLE | PACKAGE | SERVICE | NETWORK_SEGMENT
    IN_CDE_SCOPE        CHAR(1)        DEFAULT 'Y' NOT NULL,
    SEGMENTATION_NOTE   VARCHAR2(400)  ,
    REVIEWED_DATE        DATE          DEFAULT SYSDATE NOT NULL,
    REVIEWED_BY           VARCHAR2(30) DEFAULT USER NOT NULL
);

COMMENT ON TABLE CM_CDE_ASSET_SCOPE IS 'Audit register of objects inside the PCI DSS CDE boundary - CARD-003. Documentation aid only; actual network segmentation is infra, out of DB scope.';

-- Seed data documenting Epic 0.1's CDE-scoped objects
INSERT INTO CM_CDE_ASSET_SCOPE (ASSET_SCOPE_ID, OBJECT_NAME, OBJECT_TYPE, IN_CDE_SCOPE, SEGMENTATION_NOTE)
VALUES (1, 'CM_TOKEN_VAULT', 'TABLE', 'Y', 'Isolated PCI-scoped schema/VLAN per CARD-003 design; only PKG_TOKEN_VAULT has grants');

INSERT INTO CM_CDE_ASSET_SCOPE (ASSET_SCOPE_ID, OBJECT_NAME, OBJECT_TYPE, IN_CDE_SCOPE, SEGMENTATION_NOTE)
VALUES (2, 'PKG_TOKEN_VAULT', 'PACKAGE', 'Y', 'Sole service permitted to read/write CM_TOKEN_VAULT');

INSERT INTO CM_CDE_ASSET_SCOPE (ASSET_SCOPE_ID, OBJECT_NAME, OBJECT_TYPE, IN_CDE_SCOPE, SEGMENTATION_NOTE)
VALUES (3, 'CM_CARD', 'TABLE', 'N', 'Out of CDE scope - holds only masked PAN and a token reference, no raw cardholder data');
