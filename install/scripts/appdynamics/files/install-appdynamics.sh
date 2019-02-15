#!/bin/bash
######################################################
if [[ -e /opt/appdynamics/AppServerAgent-4.3.2.3/conf/controller-info.xml ]] ; then
  exit
else  
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
  /usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/common-files/appdynamics.tar.gz /home/ec2-user/
  tar zxvf appdynamics.tar.gz
  sudo chown -R ec2-user /home/ec2-user/appdynamics*
  cd /home/ec2-user/appdynamics
  hostname=`hostname`
  sed -i s/DNSNAME/$hostname/g /home/ec2-user/appdynamics/opt/appdynamics/AppServerAgent-4.3.2.3/conf/controller-info.xml
  sed -i s/DNSNAME/$hostname/g /home/ec2-user/appdynamics/opt/appdynamics/MachineAgent-4.3.2.3/conf/controller-info.xml
  sudo cp -r * /
  sudo chown -R root.root /opt/appdynamics
  sudo chmod -R 755 /opt/appdynamics
fi
