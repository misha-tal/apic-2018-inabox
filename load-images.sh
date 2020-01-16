#!/bin/bash

. config/config.props 

echo "Loading management images into registry"
${APICUP} registry-upload management $(find ${IMAGES_PATH}/ -name "management-images-kubernetes_lts_v2018.4.1.*.tgz" | head -1) ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}

echo "Loading portal images into registry"
${APICUP} registry-upload portal $(find ${IMAGES_PATH}/ -name "portal-images-kubernetes_lts_v2018.4.1.*.tgz" | head -1)  ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}

echo "Loading analytics images into registry"
${APICUP} registry-upload analytics $(find ${IMAGES_PATH}/ -name "analytics-images-kubernetes_lts_v2018.4.1.*.tgz" | head -1) ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}

echo "Loading gateway images"
docker login ${REGISTRY_HOSTNAME}:${REGISTRY_PORT} -u ${REGISTRY_USER} -p "${REGISTRY_PASSWORD}"

echo ".. loading gateway image into local registry"
docker load -i $(find ${IMAGES_PATH}/ -name "idg_dk201841*.lts.nonprod.tar.gz" | head -1)
IDG_TAG=$(docker images | egrep "^ibmcom/datapower " | awk '{print $2}')

docker tag ibmcom/datapower:${IDG_TAG} ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}/apiconnect/datapower-api-gateway:2018.4.1.9-release-nonprod

echo ".. pushing gateway image into remote registry"
docker push ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}/apiconnect/datapower-api-gateway:2018.4.1.9-release-nonprod


echo ".. loading datapower monitor image into local registry"
docker load -i $(find ${IMAGES_PATH}/ -name "dpm201841*.lts.tar.gz" | head -1)

DPM_TAG=$(docker images | egrep "^ibmcom/k8s-datapower-monitor " | awk '{print $2}')
docker tag ibmcom/k8s-datapower-monitor:${DPM_TAG} ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}/apiconnect/k8s-datapower-monitor:2018.4.1.9

echo ".. pushing datapower monitor image into remote registry"
docker push ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}/apiconnect/k8s-datapower-monitor:2018.4.1.9

echo "Done."