CREATE EXTENSION azure_storage;

SELECT azure_storage.account_add('<storage_account_name>', '<storage_account_access_key>');

SELECT path, bytes, pg_size_pretty(bytes), content_type FROM azure_storage.blob_list('<storage_account_name>','<container_name>');

CREATE TABLE customer(
	C_CustKey int NOT NULL,
	C_Name varchar(64) NULL,
	C_Address varchar(64) NULL,
	C_NationKey int NULL,
	C_Phone varchar(64) NULL,
	C_AcctBal decimal(13, 2) NULL,
	C_MktSegment varchar(64) NULL,
	C_Comment varchar(120) NULL
);

COPY customer
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/customer.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE lineitem(
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

COPY lineitem
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/lineitem.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);


CREATE TABLE nation(
	N_NationKey int NULL,
	N_Name varchar(64) NULL,
	N_RegionKey int NULL,
	N_Comment varchar(160) NULL
);

COPY nation
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/nation.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE orders(
	O_OrderKey int NULL,
	O_CustKey int NULL,
	O_OrderStatus varchar(64) NULL,
	O_TotalPrice decimal(13, 2) NULL,
	O_OrderDate timestamp NULL,
	O_OrderPriority varchar(15) NULL,
	O_Clerk varchar(64) NULL,
	O_ShipPriority int NULL,
	O_Comment varchar(80) NULL
);

COPY orders
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/orders.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE part(
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

COPY part
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/part.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE partsupp(
	PS_PartKey int NULL,
	PS_SuppKey int NULL,
	PS_AvailQty int NULL,
	PS_SupplyCost decimal(13, 2) NULL,
	PS_Comment varchar(200) NULL
);

COPY partsupp
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/partsupp.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE region(
	R_RegionKey int NULL,
	R_Name varchar(64) NULL,
	R_Comment varchar(160) NULL
);

COPY region
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/region.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);

CREATE TABLE supplier(
	S_SuppKey int NULL,
	S_Name varchar(64) NULL,
	S_Address varchar(64) NULL,
	S_NationKey int NULL,
	S_Phone varchar(18) NULL,
	S_AcctBal decimal(13, 2) NULL,
	S_Comment varchar(105) NULL
);

COPY supplier
FROM 'https://<storage_account_name>.blob.core.windows.net/<container_name>/supplier.tbl'
WITH (DELIMITER '|', FORMAT CSV, HEADER false);
