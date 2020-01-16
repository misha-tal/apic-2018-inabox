#!/bin/bash


# modify apic project template

FQDN_SUFFIX="$1"
if [[ -z "$1" ]]
then
	echo "Missing parameter - fqdn suffix, e.g. $0 test-env.demo.com"
	exit 1
fi


ENDPOINT_MANAGER="manager.${FQDN_SUFFIX}"
ENDPOINT_ANALYTICS="analytics.${FQDN_SUFFIX}"
ENDPOINT_PORTAL="portal.${FQDN_SUFFIX}"
ENDPOINT_GW="gw.${FQDN_SUFFIX}"


sed -i #{{ENDPOINT_API_MANAGER_UI}}#${ENDPOINT_MANAGER}#g apic-project/apiconnect-up.yml
sed -i #{{ENDPOINT_API_CLOUD_ADMIN_UI}}#${ENDPOINT_MANAGER}#g apic-project/apiconnect-up.yml
sed -i #{{ENDPOINT_API_CONSUMER_API}}#${ENDPOINT_MANAGER}#g apic-project/apiconnect-up.yml
sed -i #{ENDPOINT_API_PLATFORM_API}}#${ENDPOINT_MANAGER}#g apic-project/apiconnect-up.yml

sed -i #{{ENDPOINT_ANALYTICS_CLIENT}}#${ENDPOINT_ANALYTICS}#g apic-project/apiconnect-up.yml
sed -i #{{ENDPOINT_ANALYTICS_INGESTION}}#${ENDPOINT_ANALYTICS}#g apic-project/apiconnect-up.yml

sed -i #{{PORTAL_ADMIN_ENDPOINT}}#${ENDPOINT_PORTAL}#g apic-project/apiconnect-up.yml
sed -i #{{PORTAL_WWW_ENDPOINT}}#${ENDPOINT_PORTAL}#g apic-project/apiconnect-up.yml

sed -i #{{ENDPOINT_API_GATEWAY}}#${ENDPOINT_GW}#g apic-project/apiconnect-up.yml
sed -i #{{ENDPOINT_APIC_GATEWAY_SERVICE}}#${ENDPOINT_GW}#g apic-project/apiconnect-up.yml

