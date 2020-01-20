#!/bin/bash

NAMESPACE="apiconnect"

export TILLER_NAMESPACE=${NAMESPACE}


echo "Deleting helm releases"
for release in $(helm ls | grep ${NAMESPACE} | egrep "apic-portal|dynamic-gateway-service|apiconnect-2|cassandra-operator-1|apic-analytics-2" | awk '{print $1}')
do
    echo "Deleting release $release"
    helm delete --purge $release
done

echo "Deleting helm releases done."

echo "Waiting for all pods termination..."
while [[ $(kubectl -n ${NAMESPACE} get pods | egrep '^r[0-9a-f]+' | wc -l) > 0 ]]
do
    sleep 5
    echo $(kubectl -n ${NAMESPACE} get pods | egrep '^r[0-9a-f]+' | wc -l) " pods still running ..."
done

echo "==============================="
kubectl -n ${NAMESPACE} get pods 
echo "==============================="

echo "Deleteing PVCs and PVs"

for pvc_pv in $(kubectl -n ${NAMESPACE} get pvc | grep Bound | egrep 'apic-portal-www|analytics-storage|apic-portal|apiconnect-cc-|dynamic-gateway-service' | awk '{print $1":"$3}')
do
    echo $pvc_pv

    pvc=$(echo $pvc_pv | awk -F: '{print $1}')
    pv=$(echo $pvc_pv | awk -F: '{print $2}')
    
    echo "Deleting pvc $pvc"
    kubectl -n ${NAMESPACE} delete pvc $pvc
    sleep 5

    echo "Deleting pv $pv"
    kubectl delete pv $pv
done

echo "Deleteing PVCs and PVs done."