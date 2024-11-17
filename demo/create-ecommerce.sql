CREATE EXTENSION azure_storage;

SELECT azure_storage.account_add('<storage_account_name>', '<storage_account_access_key>');

SELECT path, bytes, pg_size_pretty(bytes), content_type FROM azure_storage.blob_list('<storage_account_name>','<container_name>');

CREATE SCHEMA customer;
CREATE TABLE customer.customer(
        c_custkey int NOT NULL,
        c_name varchar(64) NULL,
        c_address varchar(64) NULL,
        c_nationkey int NULL,
        c_phone varchar(64) NULL,
        c_acctbal decimal(13, 2) NULL,
        c_mktsegment varchar(64) NULL,
        c_comment varchar(120) NULL
);

COPY customer.customer
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/customer.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE "order".lineitem(
        l_orderkey int NULL,
        l_partkey int NULL,
        l_suppkey int NULL,
        l_linenumber int NULL,
        l_quantity int NULL,
        l_extendedprice decimal(13, 2) NULL,
        l_discount decimal(13, 2) NULL,
        l_tax decimal(13, 2) NULL,
        l_returnflag varchar(64) NULL,
        l_linestatus varchar(64) NULL,
        l_shipdate timestamp NULL,
        l_commitdate timestamp NULL,
        l_receiptdate timestamp NULL,
        l_shipinstruct varchar(64) NULL,
        l_shipmode varchar(64) NULL,
        l_comment varchar(64) NULL
);

COPY "order".lineitem
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/lineitem.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA common;

CREATE TABLE common.nation(
        n_nationkey int NULL,
        n_name varchar(64) NULL,
        n_regionkey int NULL,
        n_comment varchar(160) NULL
);

COPY common.nation
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/nation.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE "order"."orders"(
        o_orderkey int NULL,
        o_custkey int NULL,
        o_orderstatus varchar(64) NULL,
        o_totalprice decimal(13, 2) NULL,
        o_orderdate timestamp NULL,
        o_orderpriority varchar(15) NULL,
        o_clerk varchar(64) NULL,
        o_shippriority int NULL,
        o_comment varchar(80) NULL
);

COPY "order"."orders"
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/orders.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA stock;

CREATE TABLE stock.part(
        p_partkey int NULL,
        p_name varchar(64) NULL,
        p_mfgr varchar(64) NULL,
        p_brand varchar(64) NULL,
        p_type varchar(64) NULL,
        p_size int NULL,
        p_container varchar(64) NULL,
        p_retailprice decimal(13, 2) NULL,
        p_comment varchar(64) NULL
);

COPY stock.part
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/part.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE stock.partsupp(
        ps_partkey int NULL,
        ps_suppkey int NULL,
        ps_availqty int NULL,
        ps_supplycost decimal(13, 2) NULL,
        ps_comment varchar(200) NULL
);

COPY stock.partsupp
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/partsupp.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE common.region(
        r_regionkey int NULL,
        r_name varchar(64) NULL,
        r_comment varchar(160) NULL
);

COPY common.region
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/region.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE SCHEMA supplier;
CREATE TABLE supplier.supplier(
        s_suppkey int NULL,
        s_name varchar(64) NULL,
        s_address varchar(64) NULL,
        s_nationkey int NULL,
        s_phone varchar(18) NULL,
        s_acctbal decimal(13, 2) NULL,
        s_comment varchar(105) NULL
);

COPY supplier.supplier
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/supplier.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

SET search_path to "$user", "order", public;
CREATE OR REPLACE FUNCTION "order".lineitems_byflagandstatus_forshippeddate(date) RETURNS TABLE (l_returnflag character varying(64), l_linestatus character varying(64), sum_qty integer, sum_base_price numeric, sum_disc_price numeric, sum_charge numeric, avg_qty numeric, avg_price numeric, avg_disc numeric, count_order integer)
AS $$
SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_qty, SUM(l_extendedprice) AS sum_base_price, SUM(l_extendedprice*(1.0-l_discount)) AS sum_disc_price, SUM(l_extendedprice*(1.0-l_discount)*(1.0+l_tax)) AS sum_charge, AVG(l_quantity) AS avg_qty, AVG(l_extendedprice) AS avg_price, AVG(l_discount) AS avg_disc, COUNT(*) AS count_order FROM lineitem WHERE l_shipdate <= date ($1) - 100 GROUP BY l_returnflag, l_linestatus ORDER BY l_returnflag, l_linestatus $$
LANGUAGE SQL;
