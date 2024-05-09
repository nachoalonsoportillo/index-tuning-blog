SELECT
		 SUM(l_extendedprice*l_discount)	AS REVENUE
	FROM
		 LINEITEM
	WHERE
		 L_SHIPDATE		>= DATE '1997-01-01'
	AND	 L_SHIPDATE		< DATE '1997-01-01' + INTERVAL '1' YEAR
	AND	 l_discount		BETWEEN '0.02' - 0.01 AND '0.02' + 0.01
	AND	 L_QUANTITY		< '25';
