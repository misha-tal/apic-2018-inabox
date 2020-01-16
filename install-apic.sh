#!/bin/bash

CURRENT_PATH=$(pwd)

. config/config.props

if [[ -z "$EXTERNAL_IP_ADDRESS" ]]
then
	echo "Missing parameter - IP address"
	exit 1
fi

if [[ -z "$FQDN_SUFFIX" ]]
then
	echo "Missing parameter - fqdn suffix, e.g. test-env.demo.com"
	exit 1
fi

NAMESPACE="apiconnect"
SECRET="tangram-reg-secret"

if [[ -d ${APICUP_PROJECT_PATH} ]]
then
    echo "Project directory already exists ${APICUP_PROJECT_PATH}."
    exit 2
else
    echo "Creating project directory in ${APICUP_PROJECT_PATH}"
    mkdir -p ${APICUP_PROJECT_PATH}

    cp apic-project/* ${APICUP_PROJECT_PATH}/
fi

ENDPOINT_MANAGER="manager.${FQDN_SUFFIX}"
ENDPOINT_ANALYTICS="analytics.${FQDN_SUFFIX}"
ENDPOINT_ANALYTICS_ING="analytics-ing.${FQDN_SUFFIX}"
ENDPOINT_PORTAL_WWW="portal-www.${FQDN_SUFFIX}"
ENDPOINT_PORTAL_ADMIN="portal-admin.${FQDN_SUFFIX}"
ENDPOINT_API_GW="api-gw.${FQDN_SUFFIX}"
ENDPOINT_GWS="gws.${FQDN_SUFFIX}"

if grep --silent $ENDPOINT_MANAGER /etc/hosts
then
    echo "Host file contains apic entries."
else
    echo "Updating hosts file"
    echo "$EXTERNAL_IP_ADDRESS   $ENDPOINT_MANAGER $ENDPOINT_ANALYTICS $ENDPOINT_ANALYTICS_ING $ENDPOINT_PORTAL_WWW $ENDPOINT_PORTAL_ADMIN $ENDPOINT_API_GW $ENDPOINT_GWS" >> /etc/hosts
fi


sed -i "s#{{ENDPOINT_API_MANAGER_UI}}#${ENDPOINT_MANAGER}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_CLOUD_ADMIN_UI}}#${ENDPOINT_MANAGER}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_CONSUMER_API}}#${ENDPOINT_MANAGER}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{ENDPOINT_API_PLATFORM_API}}#${ENDPOINT_MANAGER}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml

sed -i "s#{{ENDPOINT_ANALYTICS_CLIENT}}#${ENDPOINT_ANALYTICS}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{ENDPOINT_ANALYTICS_INGESTION}}#${ENDPOINT_ANALYTICS_ING}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml

sed -i "s#{{PORTAL_ADMIN_ENDPOINT}}#${ENDPOINT_PORTAL_ADMIN}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{PORTAL_WWW_ENDPOINT}}#${ENDPOINT_PORTAL_WWW}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml

sed -i "s#{{ENDPOINT_API_GATEWAY}}#${ENDPOINT_API_GW}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{ENDPOINT_APIC_GATEWAY_SERVICE}}#${ENDPOINT_GWS}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml

sed -i "s#{{SECRET}}#${SECRET}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml
sed -i "s#{{NAMESPACE}}#${NAMESPACE}#g" ${APICUP_PROJECT_PATH}/apiconnect-up.yml


(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys get manager --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys get analytics --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys get portal --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys get gwy --validate)

sleep 5
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys install manager --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys install analytics --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys install portal --validate)
(cd ${APICUP_PROJECT_PATH}; ${CURRENT_PATH}/apicup-tools/apicup --accept-license subsys install gwy --validate)

