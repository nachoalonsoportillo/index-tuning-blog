select
	C_COUNT,
	count(*) as CUSTDIST
from
	(
		select
			C_CUSTKEY,
			count(O_ORDERKEY)
		from
			CUSTOMER left outer join ORDERS on
				C_CUSTKEY = O_CUSTKEY
				and O_COMMENT not like '%specialrequests%'
		group by
			C_CUSTKEY
	) as C_ORDERS (C_CUSTKEY, C_COUNT)
group by
	C_COUNT
order by
	CUSTDIST desc,
	C_COUNT desc;
