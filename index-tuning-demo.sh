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
az account set --subscription "$SUBSCRIPTION"
az group create --resource-group "$RESOURCEGROUP" --location "$REGION"
az postgres flexible-server create --resource-group "$RESOURCEGROUP" --name "$SERVERNAME" --location "$REGION" --public-access "0.0.0.0-255.255.255.255" --sku-name "Standard_D4ds_v5" --tier "GeneralPurpose" --high-availability "Disabled" --geo-redundant-backup "Disabled" --database-name "$DATABASE" --active-directory-auth "Disabled" --storage-auto-grow "Disabled" --storage-size 512 --version 16 --admin-user "$ADMINLOGIN" --admin-password "$PASSWORD"  --yes
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "pg_qs.query_capture_mode" --value "ALL"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "pg_qs.interval_length_minutes" --value 10
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "index_tuning.mode" --value "REPORT"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "index_tuning.analysis_interval" --value "60"
az postgres flexible-server parameter set --resource-group "$RESOURCEGROUP" --server-name "$SERVERNAME" --name "azure.extensions" --value "azure_storage"

az storage account create --resource-group "$RESOURCEGROUP" --name "$STORAGEACCOUNT" --access-tier "Hot" --kind "BlobStorage" --location "$REGION" --public-network-access "Enabled" --sku "Standard_GRS"
STORAGEACCOUNTKEY=$(az storage account keys list --resource-group "$RESOURCEGROUP" --account-name "$STORAGEACCOUNT" --query [0].value -o tsv)
az storage container create --account-name "$PREFIX" --name "$CONTAINER"
az sto
export PGHOST=$SERVERNAME.postgres.database.azure.com
export PGUSER=$ADMINLOGIN
export PGPORT=5432
export PGDATABASE=$DATABASE
export PGPASSWORD=$PASSWORD 

psql -c 'CREATE EXTENSION azure_storage;'

curl -O https://raw.githubusercontent.com/nachoalonsoportillo/index-tuning-blog/main/create-tpch.sql
sed -i "s/<storage_account_name>/$STORAGEACCOUNT/g" create-tpch.sql
ESCAPEDSTORAGEACCOUNTKEY=$(sed -e 's/[&\\/]/\\&/g; s/$/\\/' -e '$s/\\$//' <<<"$STORAGEACCOUNTKEY")
sed -i "s/<storage_account_access_key>/$ESCAPEDSTORAGEACCOUNTKEY/g" create-tpch.sql
sed -i "s/<container_name>/$CONTAINER/g" create-tpch.sql
psql -f create-tpch.sql

curl -O https://raw.githubusercontent.com/nachoalonsoportillo/index-tuning-blog/main/queries.sql
psql -f queries.sql

