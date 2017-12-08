#!/bin/bash
#Glocal Variables
appName=""
adlsAccountName=""
resourceGroup=""
location=""
privateKey=""
publicKey=""
aadAppId=""
aadSpObjectId=""
adlsPath=/
certificatePassword=""

create_adls() {
    echo "*** create_adls - begin"

    adlsAccountName=$appName"adls"

    echo -e "\tCreating [$location][$resourceGroup][$adlsAccountName]"
    az dls account create --account $adlsAccountName --resource-group $resourceGroup --location $location

    echo "*** create_adls - end"
}

generate_certificate() {
    echo "*** generate_certificate - begin"

    privateKey=$appName"_privateKey.pem"
    publicKey=$appName"_publicKey.pem"
    pfx=$appName".pfx"

    echo -e "\tGenerating certificates: $privateKey and $publicKey"
    openssl req -newkey rsa:2048 -nodes -keyout $privateKey -x509 -days 3650 -out $publicKey -subj "/C=US/ST=California/L=San Jose/O=Imanis Data/OU=IT Department/CN=imanisdata.com" -passout pass:SuperP@ssw0rd

    echo -e "\tGenerating pfx: $pfx" 
    openssl pkcs12 -export -out $pfx -inkey $privateKey -in $publicKey -passout pass:$certificatePassword

    echo "*** generate_certificate - end"
}

create_aad_app() {
    echo "*** create_aad_app - begin"

    echo -e "\tCreating AAD app: $appName"
    aadAppId=$(az ad app create --display-name $appName --homepage http://$appName --identifier-uris http://$appName --key-type AsymmetricX509Cert --key-value "$(tail -n+2 $publicKey | head -n-1 | tr -d '\n')" | jq .appId -r)
    echo -e "\taadAppId: $aadAppId"

    echo "*** create_aad_app - end"
}

create_aad_sp() {
    echo "*** create_add_sp - begin"

    aadSpObjectId=$(az ad sp create --id $aadAppId | jq .objectId -r)
    echo -e "\taadSpObjectId: $aadSpObjectId"
    
    echo "*** create_add_sp - end"
}

set_adls_permission() {
    echo "*** set_adls_permission - begin"

    az dls fs access set-entry --acl-spec default:user:$aadSpObjectId:rwx,user:$aadSpObjectId:rwx --path $adlsPath --account $adlsAccountName

    echo "*** set_adls_permission - end"
}

# $1 - appName
# $2 - resourceGroup
# $3 - location
# $4 - certificate password
main() {
    appName=$1; shift
    resourceGroup=$1; shift
    location=$1; shift
    certificatePassword=$1

    create_adls
    generate_certificate
    create_aad_app
    create_aad_sp
    set_adls_permission
}

main "$@"