#!/bin/bash

IP_ADDRESS="$1"
KUBERNETES_VERSION="1.15"
POD_NETWORK_CIDR="172.20.0.0/16"
SERVICE_NETWORK_CIDR="172.21.0.0/16"

REGISTRY_USER="admin"
REGISTRY_PASSWORD="passw0rd"
REGISTRY_HOSTNAME="registry.tangram.cloud"
REGISTRY_PORT="5000"

NAMESPACE="apiconnect"
EMAIL_ACCOUNT=admin.apicup.${IP_ADDRESS}@gmail.com

if [[ -z "$1" ]]
then
	echo "Missing parameter - IP address, e.g. $0 158.177.227.254"
	exit 1
fi

if grep --quiet -i "$REGISTRY_HOSTNAME" /etc/hosts; then
	echo "Registry is configured in hosts file"
else
	echo "Adding registry hostname to hosts file"
	echo "158.177.227.242	$REGISTRY_HOSTNAME  #container registry" >> /etc/hosts
fi


sysctl -w vm.max_map_count=262144
swapoff -a

## edit /etc/fstab and comment out the SWAP definition
## edit /etc/sysctl.conf and add as a last line "vm.max_map_count=262144"
grep "vm.max_map_count=" /etc/sysctl.conf && echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sed -i "s/^LABEL=SWAP/#LABEL=SWAP/g" /etc/fstab


DOWNLOAD_DIR=$HOME/offload_download
mkdir -p $DOWNLOAD_DIR

if [[ "skip" == "$2" ]] 
then
	echo "Skipping installations"
else
	apt update 
	apt install -y apt-transport-https docker.io curl python2.7 unzip && \
	systemctl enable docker && \
	systemctl start docker
	sleep 5
	echo "Docker installed"

	if [[ -f /etc/docker/daemon.json ]] 
	then
		if grep --quiet "{REGISTRY_HOSTNAME}" /etc/docker/daemon.json
		then
			echo "/etc/docker/daemon.json already configured for insecure registry"
		else
			echo "Should fix /etc/docker/daemon.json manually"
			exit
		fi
	else
		echo "Configuring /etc/docker/daemon.json for insecure registry"
		echo "{\
        	\"insecure-registries\" : [\"${REGISTRY_HOSTNAME}:${REGISTRY_PORT}\"] \
    	}" >> /etc/docker/daemon.json
		systemctl restart docker
	fi

	#apt install -y docker-compose
	echo "Docker installed"

	echo "Pre-installing kubernetes"
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add
	echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
	LIST=$(cat /etc/apt/sources.list.d/kubernetes.list | sort -u)
	echo $LIST > /etc/apt/sources.list.d/kubernetes.list
	
	apt update

	# get latest version
	PACKAGE_VERSION=$(curl -s https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages \
	| grep Version | awk '{print $2}' | grep "$KUBERNETES_VERSION" | tail -1)
	apt install -y kubelet=$PACKAGE_VERSION kubeadm=$PACKAGE_VERSION kubectl=$PACKAGE_VERSION 
	#kubernetes-cni=$PACKAGE_VERSION


	echo "Pre-installing helm"
	mkdir -p $DOWNLOAD_DIR/helm-install/unpacked
	wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz -O $DOWNLOAD_DIR/helm-install/helm-v2.14.3-linux-amd64.tar.gz
	tar -zxvf $DOWNLOAD_DIR/helm-install/helm-v2.14.3-linux-amd64.tar.gz --directory $DOWNLOAD_DIR/helm-install/unpacked && \
	mv $DOWNLOAD_DIR/helm-install/unpacked/linux*/helm /usr/local/bin/helm
fi


for i in $(kubeadm config images list)
do 
	docker pull $i
done

for i in $(curl -s https://docs.projectcalico.org/v3.8/manifests/calico.yaml | grep "image:" | awk '{print $2}' | sort | uniq)
do
    docker pull $i
done

echo "Done pulling images"

echo "Download calico yaml"
wget https://docs.projectcalico.org/v3.8/manifests/calico.yaml -O $DOWNLOAD_DIR/calico.yaml
echo "Download helm charts"
wget https://github.com/helm/charts/archive/master.zip -O $DOWNLOAD_DIR/master.zip 
echo "Done downloading."


echo "Configuring Kubernetes"


KUBEAPI_VERSION=$(docker images | grep "k8s.gcr.io/kube-apiserver" | grep "${KUBERNETES_VERSION}" | awk '{print $2}' | tail -1)

#kubeadm init --ignore-preflight-errors=NumCPU --apiserver-advertise-address="${IP_ADDRESS}" --pod-network-cidr="${POD_NETWORK_CIDR}" --kubernetes-version="${KUBEAPI_VERSION}" | tee -a $HOME/kubeadm-init.log
kubeadm init --ignore-preflight-errors=NumCPU --apiserver-advertise-address="${IP_ADDRESS}" --service-cidr="${SERVICE_NETWORK_CIDR}"   --pod-network-cidr="${POD_NETWORK_CIDR}" --kubernetes-version="${KUBEAPI_VERSION}" | tee -a $HOME/kubeadm-init.log


if [[ "${PIPESTATUS[0]}" != "0" ]]
then
	echo "ERROR: kubeadm init did not work as expected."
	exit
fi

echo ${PIPESTATUS[0]} 
echo $?

sleep 5

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config


sed -i "s#192.168.0.0/16#${POD_NETWORK_CIDR}#g" $HOME/offload_download/calico.yaml
kubectl apply -f $HOME/offload_download/calico.yaml
kubectl taint nodes --all node-role.kubernetes.io/master-


#https://docs.projectcalico.org/v3.8/manifests/calico.yaml

echo "source <(kubectl completion bash)" >> ~/.bashrc

echo "Fixing secret service"
/bin/rm -f /usr/bin/docker-credential-secretservice

#echo "Build SMTP server"
#№mkdir -p /data/smtp/mails
#(cd $HOME/SMTPServer && ./build.sh)


docker login ${REGISTRY_HOSTNAME}:${REGISTRY_PORT} -u ${REGISTRY_USER} -p \'"${REGISTRY_PASSWORD}"\'



echo "Load Kubernetes artefacts"

export NAMESPACE=${NAMESPACE}
kubectl create namespace $NAMESPACE
kubectl create secret docker-registry tangram-reg-secret \
  --docker-server=${REGISTRY_HOSTNAME}:${REGISTRY_PORT} --docker-username=${REGISTRY_USER} \
  --docker-password=\'"${REGISTRY_PASSWORD}"\' --docker-email=${EMAIL_ACCOUNT} \
  -n ${NAMESPACE}

kubectl create clusterrolebinding add-on-cluster-admin \
  --clusterrole=cluster-admin --serviceaccount=apiconnect:default

echo "Init helm"
helm init --tiller-namespace ${NAMESPACE}

echo "Waiting for tiller to start up"
sleep 10
echo "Installing ingress"
helm install --name ingress -f ingress-controller/nginx-ingress-values.yaml stable/nginx-ingress \
  --namespace ${NAMESPACE} --tiller-namespace ${NAMESPACE} 

kubectl create -f ./k8s-objects/storage-rbac.yaml -n ${NAMESPACE}
kubectl create -f ./k8s-objects/hostpath-provisioner.yaml -n ${NAMESPACE}
kubectl create -f ./k8s-objects/storage-class.yaml -n ${NAMESPACE}

echo "All done."


#apicup registry-upload management management-images-kubernetes_lts_v2018.4.1.*.tgz ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}
#apicup registry-upload portal portal-images-kubernetes_lts_v2018.4.1.*.tgz ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}
#apicup registry-upload analytics analytics-images-kubernetes_lts_v2018.4.1.*.tgz ${REGISTRY_HOSTNAME}:${REGISTRY_PORT}
