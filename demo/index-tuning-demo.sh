#!/bin/bash
RD='\033[0;31m'
NC='\033[0m'
SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_NAME="$(basename "$0")"
DIR_PATH="${SCRIPT_PATH%$SCRIPT_NAME}"
array=()
for i in {a..z} {0..9}; 
   do
   array[$RANDOM]=$i
done
PREFIX=$(IFS=; echo "${array[*]::12}")
RESOURCEGROUP=rg-indextuning-$PREFIX
SERVER=indextuning-pgfs-$PREFIX
ADMINLOGIN=adminuser
DATABASE=tpch
PASSWORD=S3cr3T-$PREFIX-P@sSw0Rd
STORAGEACCOUNT=$PREFIX
CONTAINER="data-to-load"
PS3='Please select the region where you want to deploy: '
options=("East Asia" "Central India" "North Europe" "Southeast Asia" "South Central US" "UK South" "West US 3")
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
printf "\n"
read -p "Enter the name or GUID of your subscription: " SUBSCRIPTION
printf "\n"
printf "Setting subscription ${RD}'${SUBSCRIPTION}'${NC} as current subscription.\n\n"
az account set --subscription "$SUBSCRIPTION"  --output none --only-show-errors
printf "Creating resource group ${RD}'${RESOURCEGROUP}'${NC} in location ${RD}'${REGION}'${NC}.\n\n"
az group create --resource-group "$RESOURCEGROUP" --location "$REGION" --output none --only-show-errors
printf "Creating instance of Azure Database for PostgreSQL Flexible Server with server name ${RD}'${SERVER}'${NC}, inside resource group ${RD}'${RESOURCEGROUP}'${NC}, and in location ${RD}'${REGION}'${NC}.\n\n"
az postgres flexible-server create --resource-group "$RESOURCEGROUP" --name "$SERVER" --location "$REGION" --public-access "0.0.0.0-255.255.255.255" --sku-name "Standard_D4ds_v5" --tier "GeneralPurpose" --high-availability "Disabled" --geo-redundant-backup "Disabled" --database-name "$DATABASE" --active-directory-auth "Disabled" --storage-auto-grow "Disabled" --storage-size 512 --version 16 --admin-user "$ADMINLOGIN" --admin-password "$PASSWORD"  --yes --output none --only-show-errors
printf "Configuring Query Store to capture ALL statements.\n\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.query_capture_mode" --value "ALL" --output none --only-show-errors
printf "Reducing Query Store aggregation interval to 10 minutes.\n\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "pg_qs.interval_length_minutes" --value 10 --output none --only-show-errors
printf "Configuring index tuning to start producing index recommendations.\n\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.mode" --value "REPORT" --output none --only-show-errors
printf "Reducing index tuning analysis interval to 60 minutes.\n\n"
printf "${RD}Note that the first index tuning session will only start 12 hours after it was enabled. Only when that tuning session completes, it will observe this value and will schedule the next run to start 60 minutes later.${NC}\n\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "index_tuning.analysis_interval" --value "60" --output none --only-show-errors
printf "Enable azure_storage extension.\n\n"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVER" --name "azure.extensions" --value "azure_storage" --output none --only-show-errors
printf "Creating storage account ${RD}'${STORAGEACCOUNT}'${NC}, in resource group ${RD}'${RESOURCEGROUP}'${NC} and location ${RD}'${REGION}'${NC}, to host the data files with which the TPCH database objects will be populated.\n\n"
az storage account create --resource-group "$RESOURCEGROUP" --name "$STORAGEACCOUNT" --access-tier "Hot" --kind "BlobStorage" --location "$REGION" --public-network-access "Enabled" --sku "Standard_GRS" --output none --only-show-errors
printf "Fetch access key of the storage account to configure azure_storage extension.\n\n"
STORAGEACCOUNTKEY=$(az storage account keys list --resource-group "$RESOURCEGROUP" --account-name "$STORAGEACCOUNT" --query [0].value -o tsv)
printf "Creating blob container ${RD}'${CONTAINER}'${NC} in storage account ${RD}'${STORAGEACCOUNT}'${NC}.\n\n"
az storage container create --account-name "$STORAGEACCOUNT" --name "$CONTAINER" --output none --only-show-errors
printf "Downloading data files from GitHub repo.\n\n"
for file in *.tbl; do
  curl "https://media.githubusercontent.com/media/nachoalonsoportillo/index-tuning-blog/main/demo/$file"
done
printf "Updloading data files to blob container ${RD}'${CONTAINER}'${NC} of storage account ${RD}'${STORAGEACCOUNT}'${NC}.\n\n"
az storage blob upload-batch --account-name "$STORAGEACCOUNT" --destination "$CONTAINER" --source "$DIR_PATH" --pattern "*.tbl" --account-key "$STORAGEACCOUNTKEY" --overwrite --output none --only-show-errors
printf "Configure environment variables for psql.\n\n"
export PGHOST=$SERVER.postgres.database.azure.com
export PGUSER=$ADMINLOGIN
export PGPORT=5432
export PGDATABASE=$DATABASE
export PGPASSWORD=$PASSWORD
printf "Customize script to create database objects for TPCH benchmark and populate them with data from files previously uploaded to blob container.\n\n"
sed "s/<storage_account_name>/$STORAGEACCOUNT/g" $DIR_PATH/create-tpch.sql > $DIR_PATH/create-tpch-"$PREFIX".sql
ESCAPEDSTORAGEACCOUNTKEY=$(sed -e 's/[&\\/]/\\&/g; s/$/\\/' -e '$s/\\$//' <<<"$STORAGEACCOUNTKEY")
sed -i "s/<storage_account_access_key>/$ESCAPEDSTORAGEACCOUNTKEY/g" $DIR_PATH/create-tpch-"$PREFIX".sql
sed -i "s/<container_name>/$CONTAINER/g" $DIR_PATH/create-tpch-"$PREFIX".sql
psql -f $DIR_PATH/create-tpch-"$PREFIX".sql >/dev/null
rm $DIR_PATH/create-tpch-"$PREFIX".sql
printf "Create an additional database wth a single table that will be queried to compete for shared buffers with the data in TPCH and, consecuently, increase IOPS.\n\n"
psql -c 'CREATE DATABASE filler;' >/dev/null
psql -d 'filler' -c 'select generate_series as id, repeat('\''X'\'', 1000) into filler from (select * from generate_series(1, 1000000));' >/dev/null
printf "Run 22 TPCH queries and 1 qery on the filler database for 12 hours.\n\n" 
URL="https://ms.portal.azure.com/?feature.customportal=false&Microsoft_Azure_OSSDatabases=ci&forceEnableFeatures=Microsoft.DBforPostgreSQL%2Fenableindextuning_public#@microsoft.onmicrosoft.com/resource"$(az postgres flexible-server show --resource-group $RESOURCEGROUP --name $SERVER --query id -o tsv)"/indexTuning"
printf "By the time the benchmark completes, you should be able to see index recommendations from $URL.\n\n"
start_time=$(date +%s)
loop=1
while true; do
  printf "Executing loop number ${RD}$loop${NC} at ${RD}$(date)${NC}.\n\n"
  loop=$((loop + 1))
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if ((elapsed_time >= 43200)); then
    break
  fi
  xargs -d "\n\n" -n 1 -P 10 psql -c >/dev/null < $DIR_PATH/compact-queries.sql
  psql -d 'filler' -c 'select count(*) from filler;' >/dev/null
  sleep 60
done
printf "Benchmark completed. Index recommendations can be seen from $URL.\n\n"
