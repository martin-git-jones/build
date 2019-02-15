#!/bin/bash -x
# These parameters are received from Jenkins
echo  InstanceType=$InstanceType
echo Java=$Java
echo Tomcat=$Tomcat
echo WarURL=$WarURL
echo AppName=$AppName
echo CommitHash=$CommitHash
echo EnvName=$EnvName
echo CostCentre=$CostCentre

# Set some defaults in case they could not be found on AWS TODO: Exit with an error if this info is not provided
if [[ -z $EnvName ]] ; then
   echo "EnvName not set"
   exit 1
fi

# Set the proxy server
export http_proxy=http://uknp-obproxy.avivaaws.com:80
export https_proxy=http://uknp-obproxy.avivaaws.com:80
export NO_PROXY=localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.ecs.com,169.254.169.254
# Configure AWS access keys
rm ~/.aws/credentials
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
/usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set default.region $REGION
/usr/local/bin/aws configure set default.output json
# Get ec2-user key
echo $ec2_key | sed 's/KEY-----/KEY-----\n/' |sed 's/-----END/\n-----END/' > ec2-key

redhat7_name="RHEL-7*AvivaBaseBuild"
BASEAMIS7=`aws ec2 describe-images --filters Name=state,Values="available" Name=name,Values="$redhat7_name" Name=tag:"BaseAmi",Values="true" --output text --query 'Images[*].[CreationDate, ImageId]' | sort -r -k 1 `
BASEAMI7A=`echo $BASEAMIS7 | awk '{print $2}'`
BASEAMI7B=`echo $BASEAMIS7 | awk '{print $4}'`
redhat6_name="RHEL-6*AvivaBaseBuild"
BASEAMIS6=`aws ec2 describe-images --filters Name=state,Values="available" Name=name,Values="$redhat6_name" Name=tag:"BaseAmi",Values="true" --output text --query 'Images[*].[CreationDate, ImageId]' | sort -r -k 1`
BASEAMI6A=`echo $BASEAMIS6 | awk '{print $2}'`
BASEAMI6B=`echo $BASEAMIS6 | awk '{print $4}'`


#BASEAMIW=`aws ec2 describe-images --filters Name=state,Values="available" Name=name,Values="Win-2012r2x64*AvivaBaseBuild" Name=tag:"BaseAmi",Values="true" --output text --query 'Images[*].[CreationDate, ImageId]' | sort -r -k 1 | head -1 | awk '{print $2}' `


case $AMIType in
    "Red Hat v7 Latest AMI") 
        BASEAMI=$BASEAMI7A;;
 	"Red Hat v6 Latest AMI") 
        BASEAMI=$BASEAMI6A;;
    "Red Hat v7 Previous AMI") 
        BASEAMI=$BASEAMI7B;;
	"Red Hat v6 Previous AMI")
        BASEAMI=$BASEAMI6B;;
esac

echo "Java version is $Java"
sed -i s/JAVAVERSION/$Java/g build.tf
sed -i s/TOMCATVERSION/$Tomcat/g build.tf
#
# check if name exists already in AWS
IP=`dig $EnvName.avivaaws.com | grep -A 1 'ANSWER SECTION' | awk '{print $5}' | tail -1`
echo "IP address is $IP"
INSTANCEID=`aws ec2 describe-instances --filter Name=private-ip-address,Values=$IP --query 'Reservations[].Instances[].[InstanceId]' --output text`
echo "Instance ID is $INSTANCEID"
STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCEID | grep -A3 $INSTANCEID | grep Name | awk '{print $2}' | sed 's/"//g'`
echo "Instance is $STATUS"
   # Get tags from current instance
if [[ ! -z $INSTANCEID ]] ; then
   REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
   AWSNAME=`aws ec2 describe-tags --filters Name=resource-id,Values="$INSTANCEID"  Name=key,Values=Name --query Tags[].Value --output text`
   echo "AWS Name is $AWSNAME"
   TAG_NAME=Costcentre_Projectcode
   COSTCENTRE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=AWSMetaData
   SUBNET=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -d ':' -f2)
   TAG_NAME=HSN
   HSN=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Schedule
   SCHEDULE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Owner
   OWNER=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   TAG_NAME=Environment_Purpose
   ENVIRONMENTPURPOSE=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
   ## Add more tags as required  
fi
   
   if [[ $STATUS =~ running ]]; then
        # Create a backup (todo)
        echo "Terminate instance $INSTANCEID and reuse name $AWSNAME and IP $IP"
        aws ec2 terminate-instances --instance-ids $INSTANCEID
        sleep 120
   else
       echo $EnvName is not running 
   fi
   
if [[ -z $AWSNAME ]] ; then
   AWSNAME='euw1bCgwPCll090'
fi

sed -i s/HOSTNAME/$EnvName/g build.tf
if [[ -z $WarURL && -z $CommitHash ]] ; then
   DeployApp=False
else
   DeployApp=True
fi
sed -i s#APPNAME#$AppName#g build.tf
sed -i s#WARURL#$WarURL#g build.tf
sed -i s/DEPLOYAPP/$DeployApp/g build.tf
sed -i s#COMMITHASH#$CommitHash#g build.tf
if [[ -z $AVAILABILITYZONE ]]; then
   AVAILABILITYZONE="eu-west-1a"
fi
## IGNORING PREVIOUS SUBNET FROM THE AWSMETADATA TAG FOR NOW TODO: CHECK THE SUBNETS
unset SUBNET 
if [[ -z $SUBNET ]]; then
   ipoctal=`echo $IP | cut -d '.' -f 3`
   if [[ $ipoctal < 16 ]]; then 
       SUBNET='subnet-777bef12'
       AVAILABILITYZONE='eu-west-1a'
   elif [[ $ipoctal < 32 ]]; then
       SUBNET='subnet-86f64af1'
       AVAILABILITYZONE='eu-west-1b'
   else
       SUBNET='subnet-83f64af4'
       AVAILABILITYZONE='eu-west-1b'
   fi
fi
sed -i s#AVAILABILITYZONE#$AVAILABILITYZONE#g build.tf
sed -i s#SUBNET#$SUBNET#g build.tf
sed -i s#AWSNAME#$AWSNAME#g build.tf
echo Set the cost centre
# Note: lowercase (entered in Jenkins) vs uppercase (taken from existing image)
sed -i s#COSTCENTRE#$CostCentre#g build.tf
echo Set the Environment Purpose
if [[ -z $ENVIRONMENTPURPOSE ]]; then
   ENVIRONMENTPURPOSE="AWS GUIDEWIRE TEST SERVER"
fi
sed -i s#ENVIRONMENTPURPOSE#"${ENVIRONMENTPURPOSE}"#g build.tf
echo Set the HSN tag
if [[ -z $HSN ]]; then
   HSN="GUIDEWIRE JENKINS DEV EC2 AWS"
fi
sed -i s#HSNTAG#"${HSN}"#g build.tf

# Use the existing IP Address if there is one
# Check in case the IP address has been taken after the instance was terminated
ping -c 1 $IP
if [[ $? == 0 ]]; then
  IP=''
fi
sed -i s#PRIVATEIP#$IP#g build.tf
# TODO: Pass the above tags as vars to terraform instead of patching the file
echo terraform apply -var source_ami=$BASEAMI -var user=$Key -var pass=$Secret -var token_gw=$Token_iam 
terraform init
terraform apply -var source_ami=$BASEAMI -var user=$Key -var pass=$Secret -var token_gw=$Token_iam

private_ip=$(terraform show | grep "private_ip" | awk '{print $3}')
if [[ -z $private_ip ]] ; then
   exit 1
fi
private_ip2=`echo $private_ip | sed 's/\./\-/g'`
instance_id=$(terraform show | grep "id = i" | awk '{print $3}')

aws ec2 create-tags --resources $instance_id --tags "Key=Hostname,Value=$private_ip2.avivaaws.com"
sleep 60
# Disable RH Pulp repo
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$private_ip "sudo yum-config-manager --disable PULP_RHEL7"
# Install Support Packages
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$private_ip "sudo yum install -y vim mailcap zip unix2dos mlocate p7zip jq"

# Install Ansible
scp  -oPasswordAuthentication=no    -o StrictHostKeyChecking=no -i ec2-key installAnsible.sh  ec2-user@$private_ip:~/
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$private_ip "sudo ~/installAnsible.sh"

# Set DNS name
if [[ -z $EnvName ]] ; then
   echo No hostname to set
else
   ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$private_ip "sudo hostnamectl set-hostname $EnvName.avivaaws.com"
   aws ec2 create-tags --resources $instance_id --tags "Key=Hostname,Value=$EnvName.avivaaws.com"
fi

# Install Boto on Jenkins Slave
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no  -i ec2-key ec2-user@localhost "sudo yum-config-manager --disable PULP_RHEL7; sudo yum install -y python-boto"

# Run Ansible locally on remote instance to install common software
scp  -oPasswordAuthentication=no   -o StrictHostKeyChecking=no -i ec2-key ansible/common.yml  ec2-user@$private_ip:~/
scp -r -oPasswordAuthentication=no -o StrictHostKeyChecking=no -i ec2-key ansible/files  ec2-user@$private_ip:~/
ssh -oPasswordAuthentication=no -x -t -t -o ForwardX11=no  -o StrictHostKeyChecking=no -i ec2-key  ec2-user@$private_ip "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -v -u ec2-user --private-key ec2-key  ~/common.yml"


