#!/bin/bash

kubeadm reset
rm -rf ~/.kube/
systemctl stop docker
systemctl disable docker
apt remove -y kubelet kubeadm kubectl docker.io
rm /etc/docker/daemon.json
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

