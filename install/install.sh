#!/bin/bash
# Set the proxy server
export http_proxy=http://uknp-obproxy.avivaaws.com:80
export https_proxy=http://uknp-obproxy.avivaaws.com:80
export NO_PROXY=localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.ecs.com,169.254.169.254
# Set AWS credentials

REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
# Configure AWS access keys
getawsaccesskeys() {
  /usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
  /usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
  /usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
  echo -n "aws_security_token = " >> ~/.aws/credentials
  echo  $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g') >> ~/.aws/credentials
  /usr/local/bin/aws configure set default.region $REGION
  /usr/local/bin/aws configure set default.output json
}
getawsaccesskeys
echo $ec2_key | sed 's/KEY-----/KEY-----\n/' |sed 's/-----END/\n-----END/' > ec2-key
# The following is a test ping
#ansible -i ec2.py -u ec2-user --private-key ec2-key  -m ping tag_GW_JavaVersion_1_6_Latest
# Install Boto on Jenkins Slave
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no  -i ec2-key ec2-user@localhost "sudo yum-config-manager --disable PULP_RHEL7; sudo yum install -y python-boto"
# Run playbooks
# JAVA - install 1.6 on all instances tagged with GW_JavaVersion_1_6_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Java/1_6_Latest/install.yml
# JAVA - install IBM 1.6 on all instances tagged with GW_JavaVersion_1_6_IBM
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Java/ibm_1_6/ibm-java-6.yml
# JAVA - install 1.7 on all instances tagged with GW_JavaVersion_1_7_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Java/1_7_Latest/install.yml
# JAVA - install 1.8 on all instances tagged with GW_JavaVersion_1_8_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Java/1_8_Latest/install.yml
# ORACLE JAVA - install 1.8 on all instances tagged with GW_JavaVersion_1_8_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Java/Oracle_1_8_Latest/install.yml
# TOMCAT - install v7 on all instances tagged with GW_Tomcat_7_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Tomcat/7_Latest/install.yml
# ALSO INSTALL APPDYNAMICS ON INSTANCES TAGGED WITH TOMCAT_V7
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/appdynamics/appdynamics.yml
# TOMCAT - install v9 on all instances tagged with GW_Tomcat_9_Latest
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/Tomcat/9_Latest/gw_tomcat_v9.yml
# Application - install PC/CC/CM on all instances tagged with GW_DeployApp_True
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ec2.py  -u ec2-user --private-key ec2-key  scripts/guidewire/install.yml
