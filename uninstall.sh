#!/bin/bash

kubeadm reset
rm -rf ~/.kube/
systemctl stop docker
systemctl disable docker
apt remove -y kubelet kubeadm kubectl docker.io
rm /etc/docker/daemon.json
