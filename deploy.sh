#!/bin/bash

#Requirements:
#   - jq
#   - Azure CLI 2.0
#   - openssl

resourceGroup=$1
location=$2 #ADLS is currently supported on eastus2, centralus an northeurope
appName=$3
certificatePassword=$4

az group create -n $resourceGroup -l $location

#Create the application on AAD, service principal and certificate
./adls.sh $appName $resourceGroup $location $certificatePassword

appId=$(az ad app show --id http://$appName | jq .appId -r)
adlsAccountName=$appName"adls"
tenantId=$(az account show | jq .tenantId -r)
certificate=$(openssl base64 -in $appName.pfx|tr -d '\n')

parameters=$(cat parameters.json)
parameters=$(echo $parameters | sed -e "s/<tenantId>/$tenantId/")
parameters=$(echo $parameters | sed -e "s/<adlsAccountName>/$adlsAccountName/")
parameters=$(echo $parameters | sed -e "s/<applicationId>/$appId/")
parameters=$(echo $parameters | sed -e "s:<certificate>:$certificate:")
parameters=$(echo $parameters | sed -e "s:<certificatePassword>:$certificatePassword:")

#echo $parameters
az group deployment create --name myDeploy --resource-group $resourceGroup --template-file ./mainTemplate.json --parameters "$parameters"