SELECT
		 L_ORDERKEY
		,SUM(l_extendedprice*(1-l_discount))	AS REVENUE
		,O_ORDERDATE
		,O_SHIPPRIORITY
	FROM
		 CUSTOMER
		,ORDERS
		,LINEITEM
	WHERE
		 C_MKTSEGMENT		= N'MACHINERY'
	AND	 C_CUSTKEY		= O_CUSTKEY
	AND	 L_ORDERKEY		= O_ORDERKEY
	AND	 O_ORDERDATE		< DATE '1995-03-21'
	AND	 L_SHIPDATE		> DATE '1995-03-21'
	GROUP BY
		 L_ORDERKEY
		,O_ORDERDATE
		,O_SHIPPRIORITY
	ORDER BY
		 REVENUE	DESC
		,O_ORDERDATE
	LIMIT 10;