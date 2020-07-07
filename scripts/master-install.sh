#!/bin/bash
# version 0.1
# Author: Marc Vogelmann
# License: GNU GENERAL PUBLIC LICENSE
# Date: 07.07.2020

# Update the host
#echo "updating host..."
#dnf update -y


# Add the other nodes to your local DNS-Record
echo "Updating /etc/hosts"
 cat <<EOF > /etc/hosts
192.168.1.47 cent8-master01
192.168.1.48 node-1 worker-node-1
192.168.1.49 node-2 worker-node-2
EOF

# Disable SELinux
setenforce 0
echo "disabled SELinux"

# Add Firewall-Rules
systemctl enable firewalld
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd –reload
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
echo "updated Firewall"

# Add Docker Repository
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

# Install containerd.io package
dnf install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

# Install latest version of Docker
echo "installing Docker"
dnf install docker-ce

# Enable and start docker
systemctl enable  docker
systemctl start docker

# Add Kubernetes Repository
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubeadm
echo "installing Kubernetes"
dnf install kubeadm -y 

# Enable and start Kubeadm
systemctl enable kubelet
systemctl start kubelet

# Creating a Control-Plane Master
# turn off swap
swapoff -a

# initialize the kubernetes master
echo "initializing Kubernetes Master"
kubeadm init

# Enable our user
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Setting up the pod network
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever