SET search_path TO "$user", "order", public;SELECT * FROM lineitems_byflagandstatus_forshippeddate('1992/12/01')
SET search_path to stock, supplier, common; SELECT s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment FROM part, supplier, partsupp, nation, region WHERE p_partkey = ps_partkey AND s_suppkey = ps_suppkey AND p_size = $1 AND p_type LIKE $2 AND s_nationkey = n_nationkey AND n_regionkey = r_regionkey AND r_name = $3 AND ps_supplycost = ( SELECT MIN(ps_supplycost) FROM partsupp, supplier, nation, region WHERE p_partkey = ps_partkey AND s_suppkey = ps_suppkey AND s_nationkey = n_nationkey AND n_regionkey = r_regionkey AND r_name = N'EUROPE' ) ORDER BY s_acctbal DESC, n_name, s_name, p_partkey LIMIT 100 \bind 50 '%NICKEL' 'EUROPE'
SET search_path TO customer, "order"; SELECT l_orderkey, SUM(l_extendedprice*(1-l_discount)) AS revenue, o_orderdate, O_SHIPPRIORITY FROM customer, orders, lineitem WHERE c_mktsegment = N'MACHINERY' AND c_custkey = o_custkey AND l_orderkey = o_orderkey AND o_orderdate < DATE ($1) AND l_shipdate > DATE ($1) GROUP BY l_orderkey, o_orderdate, O_SHIPPRIORITY ORDER BY revenue DESC, o_orderdate LIMIT 10 \bind '1995-03-21'
SET search_path TO public, "order"; SELECT o_orderpriority, COUNT(*) AS order_count FROM orders WHERE o_orderdate >= DATE ($1) AND o_orderdate < DATE ($1) + INTERVAL '3' MONTH AND EXISTS ( SELECT * FROM lineitem WHERE l_orderkey = o_orderkey AND l_commitdate < l_receiptdate ) GROUP BY o_orderpriority ORDER BY o_orderpriority \bind '1996-04-01'
SET search_path TO "order", supplier, public, common, customer; SELECT n_name, SUM(l_extendedprice*(1-l_discount)) AS revenue FROM customer, orders, lineitem, supplier, nation, region WHERE c_custkey = o_custkey AND o_orderkey = l_orderkey AND l_suppkey = s_suppkey AND C_nationKEY = s_nationkey AND s_nationkey = n_nationkey AND n_regionkey = r_regionkey AND r_name = $1 AND o_orderdate >= DATE ($2) AND o_orderdate < DATE ($2) + INTERVAL '1' YEAR GROUP BY n_name ORDER BY revenue DESC \bind 'EUROPE' '1997-01-01'
SET search_path TO "order", "$user"; SELECT SUM(l_extendedprice*l_discount) AS revenue FROM lineitem WHERE l_shipdate >= DATE ($1) AND l_shipdate < DATE ($1) + INTERVAL '1' YEAR AND l_discount BETWEEN $2 - 0.01 AND $2 + 0.01 AND l_quantity < $3 \bind '1997-01-01' '0.02' '25'
SET search_path TO public, common, supplier, "order", customer; SELECT supp_nation, CUST_nation, L_YEAR, SUM(volume) AS revenue FROM ( SELECT N1.n_name AS supp_nation, N2.n_name AS CUST_nation, EXTRACT(YEAR FROM l_shipdate) AS L_YEAR, l_extendedprice*(1-l_discount) AS volume FROM supplier, lineitem, orders, customer, nation N1, nation N2 WHERE s_suppkey = l_suppkey AND o_orderkey = l_orderkey AND c_custkey = o_custkey AND s_nationkey = N1.n_nationkey AND C_nationKEY = N2.n_nationkey AND ( (N1.n_name = $1 AND N2.n_name = $2) OR (N1.n_name = $2 AND N2.n_name = $1) ) AND l_shipdate BETWEEN DATE ($3) AND DATE ($4) ) AS SHIPPING GROUP BY supp_nation, CUST_nation, L_YEAR ORDER BY supp_nation, CUST_nation, L_YEAR \bind 'ALGERIA' 'RUSSIA' '1995-01-01' '1996-12-31'
SET search_path TO customer, stock, supplier, "order", common; SELECT o_year, SUM(CASE WHEN nation = $1 THEN volume ELSE 0 END) / SUM(volume) AS MKT_SHARE FROM ( SELECT EXTRACT(YEAR FROM o_orderdate) AS o_year, l_extendedprice * (1-l_discount) AS volume, N2.n_name AS nation FROM part, supplier, lineitem, orders, customer, nation N1, nation N2, region WHERE p_partkey = l_partkey AND s_suppkey = l_suppkey AND l_orderkey = o_orderkey AND o_custkey = c_custkey AND C_nationKEY = N1.n_nationkey AND N1.n_regionkey = r_regionkey AND r_name = $2 AND s_nationkey = N2.n_nationkey AND o_orderdate BETWEEN DATE ($3) AND DATE ($4) AND p_type = $5 ) ALL_nationS GROUP BY o_year ORDER BY o_year \bind 'RUSSIA' 'EUROPE' '01-01-95' '12-31-96' 'STANDARD POLISHED TIN'
SET search_path TO customer, stock, supplier, "order", common; SELECT nation, o_year, SUM(amount) AS SUM_PROFIT FROM ( SELECT n_name AS nation, EXTRACT(YEAR FROM o_orderdate) AS o_year, l_extendedprice*(1-l_discount)-ps_supplycost*l_quantity AS amount FROM part, supplier, lineitem, partsupp, orders, nation WHERE s_suppkey = l_suppkey AND ps_suppkey = l_suppkey AND ps_partkey = l_partkey AND p_partkey = l_partkey AND o_orderkey = l_orderkey AND s_nationkey = n_nationkey AND P_NAME LIKE $1 ) AS PROFIT GROUP BY nation, o_year ORDER BY nation, o_year DESC \bind '%blush%'
SET search_path TO "order", common, customer; SELECT c_custkey, c_name, SUM(l_extendedprice*(1-l_discount)) AS revenue, c_acctbal, n_name, C_ADDRESS, c_phone, C_COMMENT FROM customer, orders, lineitem, nation WHERE c_custkey = o_custkey AND l_orderkey = o_orderkey AND o_orderdate >= DATE ($1) AND o_orderdate < DATE ($1) + INTERVAL '3' MONTH AND L_RETURNFLAG = $2 AND C_nationKEY = n_nationkey GROUP BY c_custkey, c_name, c_acctbal, c_phone, n_name, C_ADDRESS, C_COMMENT ORDER BY revenue DESC LIMIT 20 \bind '1994-05-01' 'R'
SET search_path TO stock, supplier, common; SELECT ps_partkey, SUM(ps_supplycost*ps_availqty) AS VALUE FROM partsupp, supplier, nation WHERE ps_suppkey = s_suppkey AND s_nationkey = n_nationkey AND n_name = N'GERMANY' GROUP BY ps_partkey HAVING SUM(ps_supplycost*ps_availqty) > ( SELECT SUM(ps_supplycost*ps_availqty) * 0.0000010000 FROM partsupp, supplier, nation WHERE ps_suppkey = s_suppkey AND s_nationkey = n_nationkey AND n_name = $1 ) ORDER BY VALUE DESC \bind 'GERMANY';
SET search_path TO "order"; SELECT l_shipmode, SUM(CASE WHEN o_orderpriority = $1 OR o_orderpriority = $2 THEN 1 ELSE 0 END) AS HIGH_LINE_COUNT, SUM(CASE WHEN o_orderpriority <> $1 AND o_orderpriority <> $2 THEN 1 ELSE 0 END) AS low_line_count FROM orders, lineitem WHERE o_orderkey = l_orderkey AND l_shipmode IN ($3, $4) AND l_commitdate < l_receiptdate AND l_shipdate < l_commitdate AND l_receiptdate >= DATE ($5) AND l_receiptdate < DATE ($5) + INTERVAL '1' YEAR GROUP BY l_shipmode ORDER BY l_shipmode \bind '1-URGENT' '2-HIGH' 'AIR' 'REG AIR' '1994-01-01'
SET search_path TO "order", public, customer; SELECT c_count, count(*) AS custdist FROM ( SELECT c_custkey, COUNT(o_orderkey) FROM customer LEFT OUTER JOIN orders ON c_custkey = o_custkey AND O_COMMENT NOT LIKE $1 group BY c_custkey ) AS C_orders (c_custkey, c_count) GROUP BY c_count ORDER BY custdist DESC, c_count DESC \bind '%specialrequests%'
SET search_path TO stock, "$user", "order"; SELECT 100.00 * SUM (CASE WHEN p_type LIKE $1 THEN l_extendedprice*(1-l_discount) ELSE 0 END ) / SUM(l_extendedprice*(1-l_discount)) AS PROMO_revenue FROM lineitem, part WHERE l_partkey = p_partkey AND l_shipdate >= DATE ($2) AND l_shipdate < DATE ($2) + INTERVAL '1' MONTH \bind 'PROMO%' '1994-05-01'
SET search_path TO supplier, "order"; SELECT s_suppkey, s_name, s_address, s_phone, total_revenue FROM supplier, (SELECT l_suppkey AS supplier_NO, SUM(l_extendedprice*(1-l_discount)) AS total_revenue FROM lineitem WHERE l_shipdate >= DATE ($1) AND l_shipdate < DATE ($1) + INTERVAL '3' MONTH GROUP BY l_suppkey)revenue WHERE s_suppkey = supplier_NO AND total_revenue = ( SELECT MAX(total_revenue) FROM ( SELECT l_suppkey AS supplier_NO, SUM(l_extendedprice*(1-l_discount)) AS total_revenue FROM lineitem WHERE l_shipdate >= DATE ($1) AND l_shipdate < DATE ($1) + INTERVAL '3' MONTH GROUP BY l_suppkey ) revenue ) ORDER BY s_suppkey \bind '1993-10-01'
SET search_path TO stock, supplier; SELECT p_brand, p_type, p_size, COUNT(DISTINCT ps_suppkey) AS supplier_CNT FROM partsupp, part WHERE p_partkey = ps_partkey AND p_brand <> $1 AND p_type NOT LIKE $2 AND p_size IN ($3, $4, $5, $6, $7, $8, $9, $10) AND ps_suppkey NOT IN (SELECT s_suppkey FROM supplier WHERE s_comment LIKE $11 ) GROUP BY p_brand, p_type, p_size ORDER BY supplier_CNT DESC, p_brand, p_type, p_size \bind 'Brand#54' 'MEDIUM BRUSHED%' 5 1 43 3 14 24 30 48 '%customer%Complaints%'
SET search_path TO "$user", public, "order", stock; SELECT SUM(l_extendedprice* (1 - l_discount)) AS revenue FROM lineitem, part WHERE ( p_partkey = l_partkey AND p_brand = $1 AND p_container IN ($2, $3, $4, $5) AND l_quantity >= $6 AND l_quantity <= $6 + 10 AND p_size BETWEEN $7 AND $8 AND l_shipmode in ($9, $10) AND l_shipinstruct = $11) OR ( p_partkey = l_partkey AND p_brand = $12 AND p_container in ($13, $14, $15, $16) AND l_quantity >= $17 AND l_quantity <= $17 + 10 AND p_size between $18 AND $19 AND l_shipmode in ($9, $10) AND l_shipinstruct = $11) OR ( p_partkey = l_partkey AND p_brand = $20 AND p_container in ($21, $22, $23, $24) AND l_quantity >= $25 AND l_quantity <= $25 + 10 AND p_size between $26 AND $27 AND l_shipmode in ($9, $10) AND l_shipinstruct = $11) \bind 'Brand#24' 'SM CASE' 'SM BOX' 'SM PACK' 'SM PKG' 7 1 5 'AIR' 'AIR REG' 'DELIVER IN PERSON' 'Brand#51' 'MED BAG' 'MED BOX' 'MED PKG' 'MED PACK' 15 1 10 '3' 'LG CASE' 'LG BOX' 'LG PACK' 'LG PKG' 27 1 15
SET search_path TO stock, "order", public, common, supplier; SELECT s_name, s_address FROM supplier, nation WHERE s_suppkey IN ( SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN ( SELECT p_partkey FROM part WHERE P_NAME LIKE $1 ) AND ps_availqty > ( SELECT 0.5 * SUM(l_quantity) FROM lineitem WHERE l_partkey = ps_partkey AND l_suppkey = ps_suppkey AND l_shipdate >= DATE ($2) AND l_shipdate < DATE ($2) + INTERVAL '1' YEAR ) ) AND s_nationkey = n_nationkey AND n_name = $3 ORDER BY s_name \bind 'purple%' '1997-01-01' 'CANADA'
SET search_path TO "order", customer; SELECT c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, SUM(l_quantity) FROM customer, orders, lineitem WHERE o_orderkey IN ( SELECT l_orderkey FROM lineitem GROUP BY l_orderkey HAVING SUM(l_quantity) > $1 ) AND c_custkey = o_custkey AND o_orderkey = l_orderkey GROUP BY c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice ORDER BY o_totalprice DESC, o_orderdate LIMIT 100 \bind 313
SET search_path TO stock, pubic, "order"; SELECT SUM(l_extendedprice* (1 - l_discount)) AS revenue FROM lineitem, part WHERE ( p_partkey = l_partkey AND p_brand = $1 AND p_container IN ($2, $3, $4, $5) AND l_quantity >= $6 AND l_quantity <= $6 + 10 AND p_size BETWEEN 1 AND 5 AND l_shipmode in ($7, $8) AND l_shipinstruct = $9 ) OR ( p_partkey = l_partkey AND p_brand = $10 AND p_container in ($11, $12, $13, $14) AND l_quantity >= $15 AND l_quantity <= $15 + 10 AND p_size between 1 AND 10 AND l_shipmode in ($7, $8) AND l_shipinstruct = $9 ) OR ( p_partkey = l_partkey AND p_brand = $16 AND p_container in ($17, $18, $19, $20) AND l_quantity >= $21 AND l_quantity <= $21 + 10 AND p_size between 1 AND 15 AND l_shipmode in ($7, $8) AND l_shipinstruct = $9 ) \bind 'Brand#24' 'SM CASE' 'SM BOX' 'SM PACK' 'SM PKG' 7 'AIR' 'AIR REG' 'DELIVER IN PERSON' 'Brand#51' 'MED BAG' 'MED BOX' 'MED PKG' 'MED PACK' 15 '3' 'LG CASE' 'LG BOX' 'LG PACK' 'LG PKG' 27
SET search_path TO public, "order", customer; SELECT cntrycode, count(*) AS NUMCUST, SUM(c_acctbal) AS totacctbal FROM ( SELECT SUBSTRING(c_phone,1,2) AS cntrycode, c_acctbal FROM customer WHERE SUBSTRING(c_phone,1,2) in ($1, $2, $3, $4, $5, $6, $7, $8) AND c_acctbal > ( SELECT avg(c_acctbal) FROM customer WHERE c_acctbal > 0.00 AND SUBSTRING(c_phone,1,2) IN ($1, $2, $3, $4, $5, $6, $7, $8) ) AND NOT EXISTS ( SELECT * FROM orders where o_custkey = c_custkey ) ) AS CUSTSALE group BY cntrycode ORDER BY cntrycode \bind '11' '13' '26' '27' '19' '24' '18' ''
--SET search_path TO "order", public, common, supplier; --SELECT s_name, count(*) AS numwait FROM supplier, lineitem L1, orders, nation where s_suppkey = L1.l_suppkey AND o_orderkey = L1.l_orderkey AND O_ordersTATUS = $1 AND L1.l_receiptdate > L1.l_commitdate AND EXISTS ( SELECT * FROM lineitem L2 where L2.l_orderkey = L1.l_orderkey AND L2.l_suppkey <> L1.l_suppkey ) AND NOT EXISTS ( SELECT * FROM lineitem L3 where L3.l_orderkey = L1.l_orderkey AND L3.l_suppkey <> L1.l_suppkey AND L3.l_receiptdate > L3.l_commitdate ) AND s_nationkey = n_nationkey AND n_name = $2 group BY s_name ORDER BY numwait desc, s_name LIMIT 100 \bind 'F' 'UNITED STATES'
BEGIN TRANSACTION;UPDATE "order".lineitem SET l_discount = 1 WHERE extract(DAY FROM (l_receiptdate - l_shipdate)) > $1 \bind 29
BEGIN TRANSACTION;UPDATE stock.partsupp SET ps_supplycost = ps_supplycost * $1 FROM supplier.supplier, common.nation WHERE partsupp.ps_suppkey = supplier.s_suppkey AND nation.n_nationkey = supplier.s_nationkey AND n_name = $2 \bind 1.08 'PERU'