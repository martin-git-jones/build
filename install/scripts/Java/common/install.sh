#!/bin/bash
######################################################
# Set the proxy server
export http_proxy=http://uknp-obproxy.avivaaws.com:80
export https_proxy=http://uknp-obproxy.avivaaws.com:80
export NO_PROXY=localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.ecs.com,169.254.169.254
# Configure AWS access keys
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
/usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set default.region $REGION
/usr/local/bin/aws configure set default.output json
# Copy the certificates
mkdir ~/certs
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/AvivaGroupInternalRootCA.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/Aviva Group Internal Sub CA3.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/avivasascaroot.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/cc-gw-sit.via.novonet.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/comodoca.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/comodoim.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/comodorsaca.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/integrationavivaawscom.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/lisa_sha2.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/Oraclerootca.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/StarfieldRootCert.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/StarfieldSecureCert.cer ~/certs/
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/VizionPublicSSLto2020DER.cer ~/certs/

# import the certs into keytool
# Name of key to retrieve
TAG_NAME=GW_JavaVersion
# Grab tag value
JavaVersion=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
if [[ $JavaVersion == "Oracle_1_8_Latest" ]]; then
   javahomepath="/usr/java/jdk1.8.0_181"
   sudo rm -rf /etc/alternatives/keytool
   sudo ln -s $javahomepath/jre/bin/keytool /etc/alternatives/keytool
   sudo rm -rf /etc/alternatives/java
   sudo ln -s $javahomepath/bin/java /etc/alternatives/java
fi

if [[ $JavaVersion == "JavaVersion_IBM_1_6" ]]; then
   javahomepath="/usr/java/ibm-java-x86_64-60"
   sudo rm -rf /etc/alternatives/keytool
   sudo ln -s $javahomepath/jre/bin/keytool /etc/alternatives/keytool
   sudo rm -rf /etc/alternatives/java
   sudo ln -s $javahomepath/bin/java /etc/alternatives/java
fi

for CERT in `ls ~/certs/*cer`
  do
  ALIAS=$(basename "$CERT" | cut -d. -f1);
  keytool -import -trustcacerts -keystore $javahomepath/jre/lib/security/cacerts -storepass changeit -noprompt -alias $ALIAS -file $CERT
  sleep 2
  done
rm ~/certs/*


