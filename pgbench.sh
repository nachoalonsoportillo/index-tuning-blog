export PGHOST=<server_name>.postgres.database.azure.com
export PGUSER=adminuser
export PGPORT=5432
export PGDATABASE=tpch
export PGPASSWORD=<password>
pgbench --client=10 --no-vacuum --file Q1.sql --file Q2.sql --file Q3.sql --file Q4.sql --file Q5.sql --file Q6.sql --file Q7.sql --file Q8.sql --file Q9.sql --file Q10.sql --file Q11.sql --file Q12.sql --file Q13.sql --file Q14.sql --file Q15.sql --file Q16.sql --file Q17.sql --file Q18.sql --file Q19.sql --file Q20.sql  --file Q21.sql --file Q22.sql
