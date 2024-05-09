select
	CNTRYCODE,
	count(*) as NUMCUST,
	sum(C_ACCTBAL) as TOTACCTBAL
from
	(
		select
			substring(C_PHONE,1,2) as CNTRYCODE,
			C_ACCTBAL
		from
			CUSTOMER
		where
			substring(C_PHONE,1,2) in
				('11', '13', '26', '27', '19', '24', '18', '')
			and C_ACCTBAL > (
				select
					avg(C_ACCTBAL)
				from
					CUSTOMER
				where
					C_ACCTBAL > 0.00
					and substring(C_PHONE,1,2) in
						('11', '13', '26', '27', '19', '24', '18', '')
			)
			and not exists (
				select
					*
				from
					ORDERS
				where
					O_CUSTKEY = C_CUSTKEY
			)
	) as CUSTSALE
group by
	CNTRYCODE
order by
	CNTRYCODE;
