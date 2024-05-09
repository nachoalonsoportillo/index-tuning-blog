SELECT
		 o_orderpriority
		,COUNT(*)		AS ORDER_COUNT
	FROM
		 ORDERS
	WHERE	 O_ORDERDATE		>= DATE '1996-04-01'
	AND	 O_ORDERDATE		< DATE '1996-04-01' + INTERVAL '3' MONTH
	AND	 EXISTS
			(
			 SELECT		 *
				FROM	 LINEITEM
				WHERE	 L_ORDERKEY	= O_ORDERKEY
				AND	 L_COMMITDATE	< L_RECEIPTDATE
			)
	GROUP BY
		 o_orderpriority
	ORDER BY
		 o_orderpriority;
