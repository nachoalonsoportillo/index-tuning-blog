select
	S_NAME,
	S_ADDRESS
from
	SUPPLIER,
	NATION
where
	S_SUPPKEY in (
		select
			PS_SUPPKEY
		from
			PARTSUPP
		where
			PS_PARTKEY in (
				select
					P_PARTKEY
				from
					PART
				where
					P_NAME like 'purple%'
			)
			and PS_AVAILQTY > (
				select
					0.5 * sum(L_QUANTITY)
				from
					LINEITEM
				where
					L_PARTKEY = PS_PARTKEY
					and L_SUPPKEY = PS_SUPPKEY
					and L_SHIPDATE >= DATE '1997-01-01'
					and L_SHIPDATE < DATE '1997-01-01' + INTERVAL '1' YEAR
			)
	)
	and S_NATIONKEY = N_NATIONKEY
	and n_name = N'CANADA'
order by
	S_NAME;
