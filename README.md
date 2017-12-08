# HDInsightADLS
Sample script to deploy an Azure HDInsight cluster using ADLS and the underlying infrastructure.
The script deploys/creates:

- Resource Group
- Certificate
- Azure AD Application
- Azure AD Service Principal
- ADLS (with permission to the application)
- Azure HDInsight (using ADLS as the storage for the cluster)

## Requirements
- jq
- Azure CLI 2.0 (already configured to access the Azure Subscription)
- openssl

## Usage

```
./deploy.sh \<resource group name> \<location> \<application name> \<certificate password>
```