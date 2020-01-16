#!/bin/bash


# modify apic project template
EXTERNAL_IP_ADDRESS="$1"
if [[ -z "$1" ]]
then
	echo "Missing parameter - IP address, e.g. $0 172.17.20.100 test-env.demo.com"
	exit 1
fi

FQDN_SUFFIX="$2"
if [[ -z "$2" ]]
then
	echo "Missing parameter - fqdn suffix, e.g. $0 172.17.20.100 test-env.demo.com"
	exit 1
fi


ENDPOINT_MANAGER="manager.${FQDN_SUFFIX}"
ENDPOINT_ANALYTICS="analytics.${FQDN_SUFFIX}"
ENDPOINT_PORTAL="portal.${FQDN_SUFFIX}"
ENDPOINT_GW="gw.${FQDN_SUFFIX}"


if grep --silent $ENDPOINT_MANAGER /etc/hosts
then
    echo "Host file contains apic entries."
else
    echo "Updating hosts file"
    echo "$EXTERNAL_IP_ADDRESS   $ENDPOINT_MANAGER $ENDPOINT_ANALYTICS $ENDPOINT_PORTAL $ENDPOINT_GW" >> /etc/hosts
fi


sed -i "s#{{ENDPOINT_API_MANAGER_UI}}#${ENDPOINT_MANAGER}#g" apic-project/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_CLOUD_ADMIN_UI}}#${ENDPOINT_MANAGER}#g" apic-project/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_CONSUMER_API}}#${ENDPOINT_MANAGER}#g" apic-project/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_PLATFORM_API}}}#${ENDPOINT_MANAGER}#g" apic-project/apiconnect-up.yml

sed -i "s#{{ENDPOINT_ANALYTICS_CLIENT}}#${ENDPOINT_ANALYTICS}#g" apic-project/apiconnect-up.yml
sed -i "s#{{ENDPOINT_ANALYTICS_INGESTION}}#${ENDPOINT_ANALYTICS}#g" apic-project/apiconnect-up.yml

sed -i "s#{{PORTAL_ADMIN_ENDPOINT}}#${ENDPOINT_PORTAL}#g" apic-project/apiconnect-up.yml
sed -i "s#{{PORTAL_WWW_ENDPOINT}}#${ENDPOINT_PORTAL}#g" apic-project/apiconnect-up.yml

sed -i "s#{{ENDPOINT_API_GATEWAY}}#${ENDPOINT_GW}#g" apic-project/apiconnect-up.yml
sed -i "s#{{ENDPOINT_APIC_GATEWAY_SERVICE}}#${ENDPOINT_GW}#g" apic-project/apiconnect-up.yml

(cd apic-project; ../apicup-tools/apicup --accept-license subsys get manager --validate)
