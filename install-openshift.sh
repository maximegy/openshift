#!/bin/bash

## see: https://www.youtube.com/watch?v=-OOnGK-XeVY

export DOMAIN=${DOMAIN:="openshift.io"}
export USERNAME=${USERNAME:=maxime}
export PASSWORD=${PASSWORD:=maxime}
export VERSION=${VERSION:="v3.7.0"}
export IP="$(ip route get 8.8.8.8 | awk '{print $NF; exit}')"

echo "******"
echo "* Your domain is $DOMAIN "
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "* OpenShift version: $VERSION "
echo "******"

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config

yum install -y epel-release

yum update -y

yum install -y wget zile nano net-tools docker \
python-cryptography pyOpenSSL.x86_64 python2-pip \
openssl-devel python-devel httpd-tools NetworkManager python-passlib \
java-1.8.0-openjdk-headless "@Development Tools"

systemctl | grep "NetworkManager.*running" 
if [ $? -eq 1 ]; then
	systemctl start NetworkManager
	systemctl enable NetworkManager
fi

which ansible || pip install -Iv ansible

[ ! -d openshift-ansible ] && git clone https://github.com/openshift/openshift-ansible.git

cd openshift-ansible && git fetch && git checkout release-3.7 && cd ..

if [ -z $DISK ]; then 
	echo "Not setting the Docker storage."
else
	echo DEVS=$DISK >> /etc/sysconfig/docker-storage-setup
	echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
	echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
	echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

	systemctl stop docker

	rm -rf /var/lib/docker
	wipefs --all $DISK
	docker-storage-setup
fi

# echo {"insecure-registries" : ["172.30.0.0/16"]} > /etc/docker/daemon.json
systemctl restart docker
systemctl enable docker

	yum install -y sshpass
	ssh-keygen -q -f ~/.ssh/id_rsa -N ""
	cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	sshpass -p sogeti ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@172.16.1.31
	sshpass -p sogeti ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@172.16.1.32
	sshpass -p sogeti ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@172.16.1.33
	sshpass -p sogeti ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@172.16.1.34
	sshpass -p sogeti ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@172.16.1.35

export METRICS="True"
export LOGGING="True"

memory=$(cat /proc/meminfo | grep MemTotal | sed "s/MemTotal:[ ]*\([0-9]*\) kB/\1/")

if [ "$memory" -lt "4194304" ]; then
	export METRICS="False"
fi

if [ "$memory" -lt "8388608" ]; then
	export LOGGING="False"
fi

ansible-playbook -i ./openshift/inventory.ini openshift-ansible/playbooks/byo/config.yml

htpasswd -b /etc/origin/master/htpasswd ${USERNAME} ${PASSWORD}
oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

systemctl restart origin-master-api

echo "******"
echo "* Your console is https://console.$DOMAIN:8443"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/"
echo "******"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/
