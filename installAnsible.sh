#!/bin/bash
yum-config-manager --disable PULP_RHEL7 
wget -O /tmp/epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; rpm -i /tmp/epel-release-latest-7.noarch.rpm; 
yum install -y update
yum install -y ansible

