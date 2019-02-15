#!/bin/bash
######################################################
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


INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

copyfile() {
file=$1
APP=$2
for IP in $(cat gwipaddresses );
 do
   INSTANCE_ID=`aws ec2 describe-instances --filter Name=private-ip-address,Values=$IP --query 'Reservations[].Instances[].[InstanceId]' --output text` 
   TAG_NAME=Hostname
#  Grab tag value
   HOST=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   echo "Tag is $HOST"
   OUT=`ssh -oPasswordAuthentication=no -t -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$HOST "ls $file"`
   if [[ $OUT = $file ]] ; then 
        echo "Copying $file from $HOST for App $APP"
        mkdir -p "$HOST/$APP"
        scp -o StrictHostKeyChecking=no -i ~/.ssh/gw-tomcat-stack tomcat@$HOST:$file $HOST/$APP
        echo "Copying to AWS S3"
        filename=`echo $file|awk -F '/' '{print $(NF)}'`
 
        /usr/local/bin/aws s3 cp $HOST/$APP/$filename s3://avivauknonprod/applications/guidewire/backups/$HOST/$APP/$filename
        echo "Return code from S3 copy is $?"
   else 
        echo "No file found on $HOST"
   fi

 done
}

echo $ec2_key | sed 's/KEY-----/KEY-----\n/' |sed 's/-----END/\n-----END/' > ec2-key

## Obtain the current list from AWS
aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[PrivateIpAddress, Platform, PrivateDNSName,Tags[?Key=='Name'].Value|[0], Tags[?Key=='Owner'].Value|[0]]" --output text | grep GW.Development | grep -v windows > gwinstances

# Extract just the IP addresses
cat gwinstances | awk '{print $1}' > gwipaddresses
# copy bladelogic files
copyfile "/opt/appdynamics/AppServerAgent-4.3.2.3/conf/controller-info.xml" "bladlogic"
copyfile "/opt/appdynamics/MachineAgent-4.3.2.3/conf/controller-info.xml" "bladlogic"
# Copy the properties files
copyfile "/usr/WSApps/UKGGPC/Guidewire/config/PC/service.configuration.properties" "PC"
copyfile "/usr/WSApps/UKGGPC2/Guidewire/config/PC/service.configuration.properties" "PC2"
copyfile "/usr/WSApps/UKGGCC/Guidewire/config/CC/service.configuration.properties" "CC"
copyfile "/usr/WSApps/UKGGCM/Guidewire/config/CM/service.configuration.properties" "CM"
copyfile "/usr/WSApps/UKGGPC/Guidewire/config/PC/service.passport.properties" "PC"
copyfile "/usr/WSApps/UKGGPC2/Guidewire/config/PC/service.passport.properties" "PC2"
copyfile "/usr/WSApps/UKGGCC/Guidewire/config/CC/service.passport.properties" "CC"
copyfile "/usr/WSApps/UKGGCM/Guidewire/config/CM/service.passport.properties" "CM"
copyfile "/usr/WSApps/UKGGPC/Guidewire/config/PC/service.filetransfer.properties" "PC"
copyfile "/usr/WSApps/UKGGPC2/Guidewire/config/PC/service.filetransfer.properties" "PC2"
copyfile "/usr/WSApps/UKGGCC/Guidewire/config/CC/service.filetransfer.properties" "CC"
copyfile "/usr/WSApps/UKGGCM/Guidewire/config/CM/service.filetransfer.properties" "CM"
# Copy endpoint
copyfile "/opt/tomcat/app/conf/server.xml" "OTHER"
copyfile "/opt/tomcat/app/bin/setenv.sh" "OTHER"
# Copy certificates keystores
copyfile "/etc/pki/client_keystore.jks" "PKI"
copyfile "/etc/pki/gw_keystore.jks" "PKI"

# Copy security jar files
copyfile "/usr/java/ibm-java-x86_64-60/jre/lib/security/local_policy.jar" "security"
copyfile "/usr/java/ibm-java-x86_64-60//jre/lib/security/US_export_policy.jar" "security"
copyfile "/usr/java/ibm-java-x86_64-60//jre/lib/security/java.security.jar" "security"
# Copy the war file
copyfile "/opt/tomcat/app/webapps/pc.war" "webapps"
copyfile "/opt/tomcat/app/webapps/cc.war" "webapps"
copyfile "/opt/tomcat/app/webapps/cm.war" "webapps"
copyfile "/usr/java/ibm-java-x86_64-60/jre/lib/security/cacerts" "security"
# copy datasources
copyfile "/opt/tomcat/app/conf/Catalina/localhost/cc.xml" "datasources"
copyfile "/opt/tomcat/app/conf/Catalina/localhost/cm.xml" "datasources"
copyfile "/opt/tomcat/app/conf/Catalina/localhost/pc.xml" "datasources"
copyfile "/opt/tomcat/app/conf/Catalina/localhost/gpa.xml" "datasources"


## Backup tag information
######################################################

# Configure AWS access keys
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
/usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set default.region $REGION
/usr/local/bin/aws configure set default.output json


#INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

echo $ec2_key | sed 's/KEY-----/KEY-----\n/' |sed 's/-----END/\n-----END/' > ec2-key

## Obtain the current list from AWS
aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].[PrivateIpAddress, Platform, PrivateDNSName,Tags[?Key=='Name'].Value|[0], Tags[?Key=='Owner'].Value|[0]]" --output text | grep GW.Development | grep -v windows > gwinstances

# Extract just the IP addresses
cat gwinstances | awk '{print $1}' > gwipaddresses
for IP in $(cat gwipaddresses );
do
   INSTANCEID=`aws ec2 describe-instances --filter Name=private-ip-address,Values=$IP --query 'Reservations[].Instances[].[InstanceId]' --output text`
   TAG_NAME=Hostname
   HOST=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Name
   NAME=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Costcentre_Projectcode
   COSTCENTRE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=AWSMetaData
   SUBNET=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=HSN
   SUBNET=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Schedule
   SCHEDULE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Owner
   OWNER=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Environment_Purpose
   ENVIRONMENTPURPOSE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Availability_Zone
   AVAILABILITYZONE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
echo $HOST-Name=$NAME >> taginfo.txt
echo $HOST-IP=$IP >> taginfo.txt
echo $HOST-Costcentre=$COSTCENTRE >> taginfo.txt
echo $HOST-Subnet=$SUBNET >> taginfo.txt
   ipoctal=`echo $IP | cut -d '.' -f 3`
   if [[ $ipoctal < 16 ]]; then
       AVAILABILITYZONE='eu-west-1a'
   elif [[ $ipoctal < 32 ]]; then
       AVAILABILITYZONE='eu-west-1b'
   else
       AVAILABILITYZONE='eu-west-1b'
   fi
echo $HOST-AvailabilityZone=$AVAILABILITYZONE >> taginfo.txt
echo $HOST-EnvironmentPurpose=$ENVIRONMENTPURPOSE >> taginfo.txt
echo $HOST-Name=$NAME >> taginfo.txt
done

/usr/local/bin/aws s3 cp ./taginfo.txt s3://avivauknonprod/applications/guidewire/backups/common-files/taginfo.txt
