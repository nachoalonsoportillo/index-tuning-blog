SELECT
		L_RETURNFLAG,
		L_LINESTATUS,
		SUM(L_QUANTITY)										AS SUM_QTY,
		SUM(l_extendedprice)								AS SUM_BASE_PRICE,
		SUM(l_extendedprice*(1.0-l_discount))					AS SUM_DISC_PRICE,
		SUM(l_extendedprice*(1.0-l_discount)*(1.0+L_TAX))		AS SUM_CHARGE,
		AVG(L_QUANTITY)										AS AVG_QTY,
		AVG(l_extendedprice)								AS AVG_PRICE,
		AVG(l_discount)										AS AVG_DISC,
		COUNT(*)											AS COUNT_ORDER
	FROM
		LINEITEM
	WHERE
		L_SHIPDATE	<= date '1992/12/01' - 100
	GROUP BY
		L_RETURNFLAG,
		L_LINESTATUS
	ORDER BY
		L_RETURNFLAG,
		L_LINESTATUS;

