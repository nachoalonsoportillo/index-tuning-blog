CREATE EXTENSION azure_storage;

SELECT azure_storage.account_add('<storage_account_name>', '<storage_account_access_key>');

SELECT path, bytes, pg_size_pretty(bytes), content_type FROM azure_storage.blob_list('<storage_account_name>','<container_name>');

CREATE SCHEMA customer;

CREATE TABLE customer.customer(
        C_CustKey int NOT NULL,
        C_Name varchar(64) NULL,
        C_Address varchar(64) NULL,
        C_NationKey int NULL,
        C_Phone varchar(64) NULL,
        C_AcctBal decimal(13, 2) NULL,
        C_MktSegment varchar(64) NULL,
        C_Comment varchar(120) NULL
);

COPY customer.customer
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/customer.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA "order";

CREATE TABLE "order".lineitem(
        L_OrderKey int NULL,
        L_PartKey int NULL,
        L_SuppKey int NULL,
        L_LineNumber int NULL,
        L_Quantity int NULL,
        L_ExtendedPrice decimal(13, 2) NULL,
        L_Discount decimal(13, 2) NULL,
        L_Tax decimal(13, 2) NULL,
        L_ReturnFlag varchar(64) NULL,
        L_LineStatus varchar(64) NULL,
        L_ShipDate timestamp NULL,
        L_CommitDate timestamp NULL,
        L_ReceiptDate timestamp NULL,
        L_ShipInstruct varchar(64) NULL,
        L_ShipMode varchar(64) NULL,
        L_Comment varchar(64) NULL
);

COPY "order".lineitem
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/lineitem.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA common;

CREATE TABLE common.nation(
        N_NationKey int NULL,
        N_Name varchar(64) NULL,
        N_RegionKey int NULL,
        N_Comment varchar(160) NULL
);

COPY common.nation
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/nation.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE "order"."orders"(
        O_OrderKey int NULL,
        O_CustKey int NULL,
        O_OrderStatus varchar(64) NULL,                                                                                                                                         O_TotalPrice decimal(13, 2) NULL,
        O_OrderDate timestamp NULL,
        O_OrderPriority varchar(15) NULL,
        O_Clerk varchar(64) NULL,
        O_ShipPriority int NULL,
        O_Comment varchar(80) NULL
);

COPY "order"."orders"
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/orders.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA stock;

CREATE TABLE stock.part(
        P_PartKey int NULL,
        P_Name varchar(64) NULL,
        P_Mfgr varchar(64) NULL,
        P_Brand varchar(64) NULL,
        P_Type varchar(64) NULL,
        P_Size int NULL,
        P_Container varchar(64) NULL,
        P_RetailPrice decimal(13, 2) NULL,
        P_Comment varchar(64) NULL
);

COPY stock.part
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/part.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE stock.partsupp(
        PS_PartKey int NULL,
        PS_SuppKey int NULL,
        PS_AvailQty int NULL,
        PS_SupplyCost decimal(13, 2) NULL,
        PS_Comment varchar(200) NULL
);

COPY stock.partsupp
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/partsupp.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE common.region(
        R_RegionKey int NULL,
        R_Name varchar(64) NULL,
        R_Comment varchar(160) NULL
);

COPY common.region
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/region.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA supplier;

CREATE TABLE supplier.supplier(
        S_SuppKey int NULL,
        S_Name varchar(64) NULL,
        S_Address varchar(64) NULL,
        S_NationKey int NULL,
        S_Phone varchar(18) NULL,
        S_AcctBal decimal(13, 2) NULL,
        S_Comment varchar(105) NULL
);

COPY supplier.supplier
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/supplier.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

SET search_path to "$user", "order", public;
CREATE OR REPLACE FUNCTION "order".lineitems_byflagandstatus_forshippeddate(date) RETURNS TABLE (L_RETURNFLAG character varying(64), L_LINESTATUS character varying(64), SUM_QTY integer, SUM_BASE_PRICE numeric, SUM_DISC_PRICE numeric, SUM_CHARGE numeric, AVG_QTY numeric, AVG_PRICE numeric, AVG_DISCOUNT numeric, COUNT integer)
AS $$
SELECT L_RETURNFLAG, L_LINESTATUS, SUM(L_QUANTITY) AS SUM_QTY, SUM(l_extendedprice) AS SUM_BASE_PRICE, SUM(l_extendedprice*(1.0-l_discount)) AS SUM_DISC_PRICE, SUM(l_extendedprice*(1.0-l_discount)*(1.0+L_TAX)) AS SUM_CHARGE, AVG(L_QUANTITY) AS AVG_QTY, AVG(l_extendedprice) AS AVG_PRICE, AVG(l_discount) AS AVG_DISC, COUNT(*) AS COUNT_ORDER FROM LINEITEM WHERE L_SHIPDATE <= date ($1) - 100 GROUP BY L_RETURNFLAG, L_LINESTATUS ORDER BY L_RETURNFLAG, L_LINESTATUS $$
LANGUAGE SQL;
