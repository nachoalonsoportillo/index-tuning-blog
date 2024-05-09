#!/bin/bash
array=()
for i in {a..z} {0..9}; 
   do
   array[$RANDOM]=$i
done
PREFIX=$(IFS=; echo "${array[*]::12}")
RESOURCEGROUP=rg-indextuning-$PREFIX
SERVERNAME=indextuning-pgfs-$PREFIX
ADMINLOGIN=adminuser
DATABASE=tpch
PASSWORD=S3cr3T-$PREFIX-P@$$w0Rd
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
read -p "Enter the name or GUID of your subscription: " SUBSCRIPTION
az account set --subscription "$SUBSCRIPTION" --only-show-errors
az group create --resource-group "$RESOURCEGROUP" --location "$REGION" --only-show-errors
az postgres flexible-server create --resource-group "$RESOURCEGROUP" --name "$SERVERNAME" --location "$REGION" --public-access "0.0.0.0-255.255.255.255" --sku-name "Standard_D4ds_v5" --tier "GeneralPurpose" --high-availability "Disabled" --geo-redundant-backup "Disabled" --database-name "$DATABASE" --active-directory-auth "Disabled" --storage-auto-grow "Disabled" --storage-size 512 --version 16 --admin-user "$ADMINLOGIN" --admin-password "$PASSWORD"  --yes --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "pg_qs.query_capture_mode" --value "ALL" --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "pg_qs.interval_length_minutes" --value 10 --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "index_tuning.mode" --value "REPORT" --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "index_tuning.analysis_interval" --value "60" --only-show-errors
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "azure.extensions" --value "azure_storage" --only-show-errors
az storage account create --resource-group "$RESOURCEGROUP" --name "$STORAGEACCOUNT" --access-tier "Hot" --kind "BlobStorage" --location "$REGION" --public-network-access "Enabled" --sku "Standard_GRS" --only-show-errors
STORAGEACCOUNTKEY=$(az storage account keys list --resource-group "$RESOURCEGROUP" --account-name "$STORAGEACCOUNT" --query [0].value -o tsv)
az storage container create --account-name "$PREFIX" --name "$CONTAINER" --only-show-errors
for file in *.tbl; do
  curl "https://media.githubusercontent.com/media/nachoalonsoportillo/index-tuning-blog/main/$file"
done
az storage blob upload-batch --account-name "$STORAGEACCOUNT" --destination "$CONTAINER" --source "." --pattern "*.tbl" --account-key "$STORAGEACCOUNTKEY" --overwrite --only-show-errors
export PGHOST=$SERVERNAME.postgres.database.azure.com
export PGUSER=$ADMINLOGIN
export PGPORT=5432
export PGDATABASE=$DATABASE
export PGPASSWORD=$PASSWORD
psql -c 'CREATE EXTENSION azure_storage;'
sed "s/<storage_account_name>/$STORAGEACCOUNT/g" create-tpch.sql > create-tpch-"$PREFIX".sql
ESCAPEDSTORAGEACCOUNTKEY=$(sed -e 's/[&\\/]/\\&/g; s/$/\\/' -e '$s/\\$//' <<<"$STORAGEACCOUNTKEY")
sed -i "s/<storage_account_access_key>/$ESCAPEDSTORAGEACCOUNTKEY/g" create-tpch-"$PREFIX".sql
sed -i "s/<container_name>/$CONTAINER/g" create-tpch-"$PREFIX".sql
psql -f create-tpch-"$PREFIX".sql >/dev/null
rm create-tpch-"$PREFIX".sql
start_time=$(date +%s)
while true; do
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if ((elapsed_time >= 18000)); then
    break
  fi
  xargs -d "\n" -n 1 -P 10 psql -c < compact-queries.sql
  sleep 60
done