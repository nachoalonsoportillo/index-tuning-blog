SELECT
		 100.00 * SUM	(CASE
			WHEN p_type LIKE 'PROMO%'	THEN l_extendedprice*(1-l_discount)
							ELSE 0	END
				) / SUM(l_extendedprice*(1-l_discount))		AS PROMO_REVENUE
	FROM
		 LINEITEM
		,PART
	WHERE
		 L_PARTKEY		= P_PARTKEY
	AND	 L_SHIPDATE		>= DATE '1994-05-01'
	AND	 L_SHIPDATE		< DATE '1994-05-01' + INTERVAL '1' MONTH;
