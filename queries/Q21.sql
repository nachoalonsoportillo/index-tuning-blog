select
	S_NAME,
	count(*) as NUMWAIT
from
	SUPPLIER,
	LINEITEM L1,
		ORDERS,
	NATION
where
	S_SUPPKEY = L1.L_SUPPKEY
		and O_ORDERKEY = L1.L_ORDERKEY
	and O_ORDERSTATUS = 'F'
	and L1.L_RECEIPTDATE > L1.L_COMMITDATE
	and exists (
		select
			*
		from
			LINEITEM L2
		where
			L2.L_ORDERKEY = L1.L_ORDERKEY
			and L2.L_SUPPKEY <> L1.L_SUPPKEY
	)
	and not exists (
		select
			*
		from
			LINEITEM L3
		where
			L3.L_ORDERKEY = L1.L_ORDERKEY
			and L3.L_SUPPKEY <> L1.L_SUPPKEY
			and L3.L_RECEIPTDATE > L3.L_COMMITDATE
	)
	and S_NATIONKEY = N_NATIONKEY
	and n_name = N'UNITED STATES'
group by
	S_NAME
order by
	NUMWAIT desc,
	S_NAME
LIMIT 100;
