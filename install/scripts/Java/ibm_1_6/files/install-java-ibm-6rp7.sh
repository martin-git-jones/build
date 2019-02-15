#!/bin/bash
######################################################
# Check if installed
javahomepath="/usr/java/ibm-java-x86_64-60"
if [[ -e $javahomepath ]] ; then
   exit 0
fi
# Set the proxy server
export http_proxy=http://uknp-obproxy.avivaaws.com:80
export https_proxy=http://uknp-obproxy.avivaaws.com:80
export NO_PROXY=localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.ecs.com,169.254.169.254
# Configure AWS access keys
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
/usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set default.region $REGION
/usr/local/bin/aws configure set default.output json
# install the common files
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/common-files/java_ibm_1_6RP7.tar /home/ec2-user/
sudo chown ec2-user /home/ec2-user/java_ibm_1_6RP7.tar
cd /home/ec2-user
tar xvf java_ibm_1_6RP7.tar
cd /home/ec2-user/java_ibm_1_6RP7
sudo cp -r * /
sudo chown -R root.root /usr/java/
sudo chmod -R 755 /usr/java/
# install files from the earlier backups
cd /home/ec2-user
hostname=`hostname`
/usr/local/bin/aws s3 cp --recursive s3://avivauknonprod/applications/guidewire/backups/$hostname/ /home/ec2-user/
if [[ -e /etc/pki/gw_keystore.jks ]]; then
  sudo mkdir /etc/pki/
  sudo cp /home/ec2-user/PKI/* /etc/pki/
  sudo chown root.root /etc/pki/client_keystore.jks
  sudo chown root.root /etc/pki/gw_keystore.jks
  sudo chmod 644 /etc/pki/client_keystore.jks
  sudo chown 644 /etc/pki/gw_keystore.jks
fi
if [[ -e /home/ec2-user/security/cacerts ]] ; then
  cp /home/ec2-user/security/cacerts $javahomepath/jre/lib/security/cacerts
  sudo chown root.root $javahomepath/jre/lib/security/cacerts
  sudo chmod 644 $javahomepath/jre/lib/security/cacerts
  cp /home/ec2-user/security/local_policy.jar $javahomepath/jre/lib/security/local_policy.jar
  sudo chown root.root $javahomepath/jre/lib/security/local_policy.jar
  sudo chmod 644 $javahomepath/jre/lib/security/local_policy.jar
  cp /home/ec2-user/security/US_export_policy.jar $javahomepath/jre/lib/security/US_export_policy.jar
  sudo chown root.root $javahomepath/jre/lib/security/US_export_policy.jarr
  sudo chmod 644 $javahomepath/jre/lib/security/US_export_policy.jar
fi

# set the alternates
javahomepath="/usr/java/ibm-java-x86_64-60"
sudo rm -rf /etc/alternatives/keytool
sudo ln -s $javahomepath/jre/bin/keytool /etc/alternatives/keytool
sudo rm -rf /etc/alternatives/java
sudo ln -s $javahomepath/bin/java /etc/alternatives/java
# remove install files
sudo rm -rf /home/ec2-user/java_ibm_1_6RP7*
sudo rm -rf /home/ec2-user/PKI/*
sudo rm -rf /home/ec2-user/security/*


