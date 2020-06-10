#/bin/bash

set -e

opsman=$1
pd=$2

# Accessing Ops Manager API
uaac target https://$opsman/uaa --skip-ssl-validation
uaac token owner get -s '' -p ${pd} opsman admin
access_token=$(uaac contexts |grep -A6 /uaa |grep access |cut -d ' ' -f 8)
guid=$(curl -s "https://$opsman/api/v0/deployed/products" -X GET -H "Authorization: Bearer $access_token" --insecure |jq -r .[].guid |grep pivotal)
pksumac=$(curl -s "https://$opsman/api/v0/deployed/products/$guid/credentials/.properties.pks_uaa_management_admin_client" -X GET -H "Authorization: Bearer $access_token" --insecure | jq -r .credential.value.secret)

echo "PKS UAA Management Admin Client: $pksumac"

latest=$(curl  http://10.193.255.12/public_files/pivnet_files/ | grep pks-linux | cut -d '"' -f 8| tail -1)
wget http://10.193.255.12/public_files/pivnet_files/$latest

chmod +x pks-linux*

mv pks-linux* /usr/local/bin/pks
uaac target https://opsman:8443 --skip-ssl-validation
uaac token client get admin -s $pksumac
uaac user add lab-admin --emails lab-admin@vmware.com -p VMware1!
uaac member add pks.clusters.admin lab-admin
pks create-cluster cluster1 -e cluster1.lab.local -p small
