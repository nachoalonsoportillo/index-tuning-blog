SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_NAME="/$(basename "$0")"
DIR_PATH="${SCRIPT_PATH%$SCRIPT_NAME}"
array=()
for i in {a..z} {0..9};
   do
   array[$RANDOM]=$i
done
PREFIX=$(IFS=; echo "${array[*]::12}")
PREFIX=demo
RESOURCEGROUP=rg-indextuning-$PREFIX
SERVER=indextuning-$PREFIX
ADMINLOGIN=adminuser
DATABASE=ecommerce
PASSWORD=S3cr3T-$PREFIX-P@sSw0Rd
STORAGEACCOUNT=indextuning$PREFIX
CONTAINER="data-to-load"
PS3='Please select the region where you want to deploy: '
options=("East Asia" "Central India" "North Europe" "Southeast Asia" "South Central US" "UK South" "West US 3" "East US 2")
select REGION in "${options[@]}"
do
  case $REGION in
    *)
      if [[ ! -z "$REGION" ]]
      then
        break
      fi
      ;;
  esac
done
printf "[$(date -u)] Create resource group '${RESOURCEGROUP}' in location '${REGION}'.\n"
az group create --resource-group "$RESOURCEGROUP" --location "$REGION" --output none --only-show-errors
printf "[$(date -u)] Create Azure Monitor Log Analytics workspace with name '${SERVER}', inside resource group '${RESOURCEGROUP}', and in location '${REGION}'.\n"
LAWS=$(az monitor log-analytics workspace create --resource-group "$RESOURCEGROUP" --name "$SERVER" --location "$REGION" --sku "Standalone" --query "id" --output tsv --only-show-errors | tr -d "\r")
printf "[$(date -u)] Create instance of Azure Database for PostgreSQL Flexible Server with server name '${SERVER}', inside resource group '${RESOURCEGROUP}', and in location '${REGION}'.\n"
PGFS=$(az postgres flexible-server create --resource-group "$RESOURCEGROUP" --name "$SERVER" --location "$REGION" --public-access "0.0.0.0-255.255.255.255" --sku-name "Standard_D8ds_v4" --tier "GeneralPurpose" --high-availability "Disabled" --geo-redundant-backup "Disabled" --database-name "$DATABASE" --active-directory-auth "Disabled" --storage-auto-grow "Disabled" --storage-size 128 --version 16 --admin-user "$ADMINLOGIN" --admin-password "$PASSWORD" --yes --query "id" --output tsv --only-show-errors | tr -d "\r")
printf "[$(date -u)] Configure Query Store to capture ALL statements.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.query_capture_mode" --value "ALL" --output none --only-show-errors
printf "[$(date -u)] Reduce Query Store aggregation interval to 10 minutes.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.interval_length_minutes" --value 10 --output none --only-show-errors
printf "[$(date -u)] Configure Query Store to save query plans.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.store_query_plans" --value "ON" --output none --only-show-errors
printf "[$(date -u)] Configure index tuning to start producing index recommendations.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.mode" --value "REPORT" --output none --only-show-errors
printf "[$(date -u)] Reduce index tuning analysis interval to 60 minutes.\n"
printf "[$(date -u)] Note that the first index tuning session will only start 12 hours after it was enabled. Only when that tuning session completes, it will observe this value and will schedule the next run to start 60 minutes later.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.analysis_interval" --value "60" --output none --only-show-errors
printf "[$(date -u)] Enable azure_storage extension.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "azure.extensions" --value "azure_storage" --output none --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "metrics.collector_database_activity" --value "ON" --output none --only-show-errors
printf "[$(date -u)] Enable autovacuum metrics.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "metrics.autovacuum_diagnostics" --value "ON" --output none --only-show-errors
printf "[$(date -u)] Enable track_io_timing.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "track_io_timing" --value "ON" --output none --only-show-errors
printf "[$(date -u)] Enable pgms_wait_sampling.query_capture_mode.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pgms_wait_sampling.query_capture_mode" --value "ALL" --output none --only-show-errors
printf "[$(date -u)] Create diagnostic settings to collect metrics and logs to compare improvements after applying index recommendations.\n"
az monitor diagnostic-settings create --name "index-tuning" --resource "$PGFS" --workspace "$LAWS" --metrics '[{"category":"AllMetrics","enabled":true,"retentionPolicy":{"days":0,"enabled":false}}]' --logs "[{"categoryGroup":"audit","enabled":true,"retentionPolicy":{"days":0,"enabled":false}},{"categoryGroup":"allLogs","enabled":true,"retentionPolicy":{"days":0,"enabled":false}}]" --output none --only-show-errors
printf "[$(date -u)] Create storage account '${STORAGEACCOUNT}', in resource group '${RESOURCEGROUP}' and location '${REGION}', to host the data files with which the ecommerce database objects will be populated.\n"
az storage account create --resource-group "$RESOURCEGROUP" --name "$STORAGEACCOUNT" --access-tier "Hot" --kind "BlobStorage" --location "$REGION" --public-network-access "Enabled" --sku "Standard_GRS" --output none --only-show-errors
printf "[$(date -u)] Fetch access key of the storage account to configure azure_storage extension.\n"
STORAGEACCOUNTKEY=$(az storage account keys list --resource-group "$RESOURCEGROUP" --account-name "$STORAGEACCOUNT" --query [0].value -o tsv)
printf "[$(date -u)] Create blob container '${CONTAINER}' in storage account '${STORAGEACCOUNT}'.\n"
az storage container create --account-name "$STORAGEACCOUNT" --name "$CONTAINER" --output none --only-show-errors
printf "[$(date -u)] Download data files from GitHub repo.\n"
file_names=("customer" "lineitem" "nation" "orders" "part" "partsupp" "region" "supplier")
for file in "${file_names[@]}"
do
  curl -O "https://media.githubusercontent.com/media/nachoalonsoportillo/index-tuning-blog/main/demo/$file.tbl"
done
printf "[$(date -u)] Upload data files to blob container '${CONTAINER}' of storage account '${STORAGEACCOUNT}'.\n"
az storage blob upload-batch --account-name "$STORAGEACCOUNT" --destination "$CONTAINER" --source "$DIR_PATH" --pattern "*.tbl" --account-key "$STORAGEACCOUNTKEY" --overwrite --output none --only-show-errors
printf "[$(date -u)] Configure environment variables for psql.\n"
export PGHOST=$SERVER.postgres.database.azure.com
export PGUSER=$ADMINLOGIN
export PGPORT=5432
export PGDATABASE=$DATABASE
export PGPASSWORD=$PASSWORD
printf "[$(date -u)] Customize script to create database objects for ecommerce benchmark and populate them with data from files previously uploaded to blob container.\n"
sed -i "s/<storage_account_name>/$STORAGEACCOUNT/g" $DIR_PATH/create-ecommerce.sql
ESCAPEDSTORAGEACCOUNTKEY=$(echo $STORAGEACCOUNTKEY | tr -d '\r' | sed 's/[/]/çÇçÇ/g')
sed -i "s/<storage_account_access_key>/$ESCAPEDSTORAGEACCOUNTKEY/g" $DIR_PATH/create-ecommerce.sql
sed -i "s/çÇçÇ/\//g" $DIR_PATH/create-ecommerce.sql
sed -i "s/<container_name>/$CONTAINER/g" $DIR_PATH/create-ecommerce.sql
psql -f $DIR_PATH/create-ecommerce.sql >/dev/null
#rm $DIR_PATH/create-ecommerce.sql
printf "[$(date -u)] Run ANALYZE on all tables.\n"
table_names=("customer" "lineitem" "nation" "orders" "part" "partsupp" "region" "supplier")
for table in "${table_names[@]}"
do
  printf "[$(date -u)] Run ANALYZE on $table.\n"
  psql -c "ANALYZE $table;" >/dev/null
done
printf "[$(date -u)] Sleep for 15 minutes.\n"
sleep 15m
printf "[$(date -u)] Run 22 ecommerce queries for 12 hours.\n"
URL="https://ms.portal.azure.com/?feature.customportal=false&Microsoft_Azure_OSSDatabases=ci&forceEnableFeatures=Microsoft.DBforPostgreSQL%2Fenableindextuning_public#@microsoft.onmicrosoft.com/resource"$(az postgres flexible-server show --resource-group $RESOURCEGROUP --name $SERVER --query id -o tsv)"/indexTuning"
printf "[$(date -u)] By the time the benchmark completes, you should be able to see index recommendations from $URL.\n"
start_time=$(date +%s)
sed -i '/^$/d' queries.sql
queries=()
pids=()
while IFS= read -r line; do
  queries+=("$line")
done < queries.sql
sleep 1 &
pids[0]=$!
for ((i=0; i<${#queries[@]}; i++)); do
  pids[$i]=${pids[0]}
done
loop=1
create_index=2
while true; do
  printf "[$(date -u)] Enter loop number $loop.\n"
  loop=$[loop+1]
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if ((elapsed_time >= 4000)); then
    if ((create_index >= 2)); then
      sleep 10
      kill $(jobs -p)
      printf "[$(date +%s)] Create ps_partkey_idx index.\n"
      psql -c "create index ps_partkey_idx on public.partsupp(ps_partkey);"
      printf "[$(date +%s)] Create ps_suppkey_idx index.\n"
      psql -c "create index ps_suppkey_idx on public.partsupp(ps_suppkey);"
      printf "[$(date +%s)] Create l_partkey_idx index.\n"
      psql -c "create index concurrently l_partkey_idx on public.lineitem(l_partkey);"
      printf "[$(date +%s)] Create s_suppkey_idx index.\n"
      psql -c "create index s_suppkey_idx on public.supplier(s_suppkey);"
      printf "[$(date +%s)] Create l_orderkey_l_shipdate_idx index.\n"
      psql -c "create index l_orderkey_l_shipdate_idx on public.lineitem(l_orderkey,l_shipdate);"
      printf "[$(date +%s)] Create l_orderkey_idx index.\n"
      psql -c "create index l_orderkey_idx on public.lineitem(l_orderkey);"
      printf "[$(date +%s)] Create o_orderkey_idx index.\n"
      psql -c "create index o_orderkey_idx on public.orders(o_orderkey);"
      printf "[$(date +%s)] Create o_custkey_o_orderdate_idx index.\n"
      psql -c "create index o_custkey_o_orderdate_idx on public.orders(o_custkey,o_orderdate);"
      printf "[$(date +%s)] Create o_custkey_idx index.\n"
      psql -c "create index o_custkey_idx on public.orders(o_custkey);"
      printf "[$(date +%s)] Create l_shipdate_idx index.\n"
      psql -c "create index l_shipdate_idx on public.lineitem(l_shipdate);"
      sleep 1 &
      pids[0]=$!
      for ((i=0; i<${#queries[@]}; i++)); do
        pids[$i]=${pids[0]}
      done
      create_index=1
    fi
  fi
  if ((elapsed_time >= 18000)); then
    if ((create_index >= 1)); then
      sleep 10
      kill $(jobs -p)
      printf "[$(date +%s)] Create l_shipinstruct_idx index.\n"
      psql -c "create index l_shipinstruct_idx on public.lineitem(l_shipinstruct);"
      printf "[$(date +%s)] Create p_partkey_p_brand_idx index.\n"
      psql -c "create index p_partkey_p_brand_idx on public.part(p_partkey,p_brand);"
      printf "[$(date +%s)] Create c_acctbal_idx index.\n"
      psql -c "create index c_acctbal_idx on public.customer(c_acctbal);"
      printf "[$(date +%s)] Create o_orderdate_idx index.\n"
      psql -c "create index o_orderdate_idx on public.orders(o_orderdate);"
      printf "[$(date +%s)] Create c_custkey_idx index.\n"
      psql -c "create index c_custkey_idx on public.customer(c_custkey);"
      printf "[$(date +%s)] Continue running workload with indexes created.\n"
      sleep 1 &
      pids[0]=$!
      for ((i=0; i<${#queries[@]}; i++)); do
        pids[$i]=${pids[0]}
      done
      create_index=0
    fi
  fi
  if ((elapsed_time >= 12000)); then
    kill $(jobs -p)
    break
  fi
  for i in "${!queries[@]}"
  do
    if [[ $(ps -p ${pids[$i]} | wc -l) -eq 1 ]]
    then
      printf "%s\t%s\n" "$i" "${queries[$i]}"
      psql -c "${queries[$i]}" > /dev/null &
      pids[$i]=$!
    fi
  done
  MINWAIT=3
  MAXWAIT=15
  sleep $((MINWAIT+RANDOM % (MAXWAIT-MINWAIT)))
done
printf "[$(date -u)] Benchmark completed, now you should be able to see index recommendations from $URL.\n"
printf "[$(date -u)] Configure Query Store to capture NONE statements.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.query_capture_mode" --value "NONE" --output none --only-show-errors
printf "[$(date -u)] Extend Query Store aggregation interval to 15 minutes.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.interval_length_minutes" --value 15 --output none --only-show-errors
printf "[$(date -u)] Configure Query Store to stop saving query plans.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.store_query_plans" --value "OFF" --output none --only-show-errors
printf "[$(date -u)] Configure index tuning to stop producing index recommendations.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.mode" --value "OFF" --output none --only-show-errors
printf "[$(date -u)] Extend index tuning analysis interval to 720 minutes.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.analysis_interval" --value "720" --output none --only-show-errors
printf "[$(date -u)] Disable enhanced metrics.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "metrics.collector_database_activity" --value "OFF" --output none --only-show-errors
printf "[$(date -u)] Disable autovacuum metrics.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "metrics.autovacuum_diagnostics" --value "OFF" --output none --only-show-errors
printf "[$(date -u)] Disable track_io_timing.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "track_io_timing" --value "OFF" --output none --only-show-errors
printf "[$(date -u)] Disable pgms_wait_sampling.query_capture_mode.\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pgms_wait_sampling.query_capture_mode" --value "NONE" --output none --only-show-errors
