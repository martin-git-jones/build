#!/bin/bash
######################################################
# Check if installed
if [[ -e /opt/tomcat ]] ; then
   exit 0
fi
hostname=`hostname`
servername=`hostname -s`
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
INSTANCEID=`curl http://169.254.169.254/latest/meta-data/instance-id`

# install the common files
cd /home/ec2-user
/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/common-files/tomcat7.tar.gz /home/ec2-user/
sudo chown ec2-user /home/ec2-user/tomcat7.tar.gz
tar zxvf tomcat7.tar.gz
cd /home/ec2-user/tomcat7
# patch the server name in to the tomcat config
sed -i s/DNSNAME/$hostname/g opt/tomcat/app/bin/setenv.sh
sed -i s/HOSTNAME/$servername/g opt/tomcat/app/bin/setenv.sh
  # patch the datasource files with the server name
TAG_NAME=Name
# Grab tag value
awsname=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=eu-west-1 --output=text | cut -f5)
dbname=`echo "$awsname" | tr '[:upper:]' '[:lower:]'`.czup1bxlng88.eu-west-1.rds.amazonaws.com
sed -i s/rds-db-hostname/$dbname/g  opt/tomcat/app/conf/Catalina/localhost/pc.xml
sed -i s/rds-db-hostname/$dbname/g  opt/tomcat/app/conf/Catalina/localhost/cc.xml
sed -i s/rds-db-hostname/$dbname/g  opt/tomcat/app/conf/Catalina/localhost/cm.xml
sed -i s/rds-db-hostname/$dbname/g  opt/tomcat/app/conf/Catalina/localhost/gpa.xml
# Find the app name in order to set it in setenv.sh
TAG_NAME=GW_AppName
# Grab tag value
appname=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
if [[ -z $appname ]]; then
  appcode=`echo $servername | cut -d '-' -f 3`
else
  appcode=`echo $appname | cut -d '.' -f 1`
fi
sed -i s/aviva.gw.XX/aviva.gw.$appcode/g opt/tomcat/app/bin/setenv.sh
### create Tomcat user ###
echo "creating tomcat user"
sudo groupadd tomcat
sudo useradd -M -s /bin/bash -g tomcat -d /opt/tomcat/app tomcat
# Copy files to local file system
sudo cp -r * /
# Set file ownership and permissions
sudo chown -R tomcat.tomcat /opt/tomcat
sudo chown -R tomcat.tomcat /usr/WSApps/
sudo chmod -R 755 /opt/tomcat
sudo chmod -R 755 /usr/WSApps
sudo chmod -R 755 /etc/systemd/system/tomcat.service

# install files from the earlier backups
cd /home/ec2-user
sudo chown -R ec2-user /home/ec2-user/*
/usr/local/bin/aws s3 cp --recursive s3://avivauknonprod/applications/guidewire/backups/$hostname/ /home/ec2-user/
if [[ -e ./PC/service.configuration.properties ]]; then
sudo mkdir -p /usr/WSApps/UKGGPC/Guidewire/config/PC
sudo cp  ./PC/* /usr/WSApps/UKGGPC/Guidewire/config/PC/
sudo chown -R tomcat.tomcat /usr/WSApps
sudo chmod 755 /usr/WSApps/
sudo chmod 700 /usr/WSApps/UKGGPC/Guidewire/config/PC/*
fi
if [[ -e ./PC2/service.configuration.properties ]]; then
sudo mkdir -p /usr/WSApps/UKGGPC2/Guidewire/config/PC
sudo cp  ./PC2/* /usr/WSApps/UKGGPC2/Guidewire/config/PC/
sudo chown -R tomcat.tomcat /usr/WSApps
sudo chmod 755 /usr/WSApps/
sudo chmod 700 /usr/WSApps/UKGGPC2/Guidewire/config/PC/*
fi
if [[ -e ./CC/service.configuration.properties ]]; then
sudo mkdir -p /usr/WSApps/UKGGCC/Guidewire/config/PC
sudo cp  ./CC/* /usr/WSApps/UKGGCC/Guidewire/config/CC/
sudo chown -R tomcat.tomcat /usr/WSApps
sudo chmod 755 /usr/WSApps/
sudo chmod 700 /usr/WSApps/UKGGPC/Guidewire/config/CC/*
fi
if [[ -e ./CM/service.configuration.properties ]]; then
sudo mkdir -p /usr/WSApps/UKGGPC/Guidewire/config/CM
sudo cp  ./CM/* /usr/WSApps/UKGGPC/Guidewire/config/CM/
sudo chown -R tomcat.tomcat /usr/WSApps
sudo chmod 755 /usr/WSApps/
sudo chmod 700 /usr/WSApps/UKGGPC/Guidewire/config/CM/*
fi

if [[ -e ./webapps ]]; then
  sudo mkdir -p /opt/tomcat/app/webapps
  sudo cp /home/ec2-user/webapps/* /opt/tomcat/app/webapps/
  sudo chown tomcat.tomcat /opt/tomcat/app/webapps/*
  sudo chmod 600 /opt/tomcat/app/webapps/*
fi

if [[ -e ./datasources ]]; then
  sudo mkdir -p /opt/tomcat/app/conf/Catalina/localhost/
  sudo cp /home/ec2-user/datasources/* /opt/tomcat/app/conf/Catalina/localhost/
  sudo chown -R tomcat.tomcat /opt/tomcat/app/conf/Catalina/localhost
  sudo chmod -R 755 /opt/tomcat/app/conf/Catalina/localhost
fi

if [[ -e /home/ec2-user/OTHER/server.xml ]] ; then
  cp /home/ec2-user/OTHER/server.xml /opt/tomcat/app/conf/server.xml
  sudo chown tomcat.tomcat /opt/tomcat/app/conf/server.xml
  sudo chmod 755 /opt/tomcat/app/conf/server.xml
fi

if [[ -e /home/ec2-user/OTHER/setenv.sh ]] ; then
  cp /home/ec2-user/OTHER/setenv.sh /opt/tomcat/app/conf/setenv.sh
  sudo chown tomcat.tomcat /opt/tomcat/app/conf/setenv.sh
  sudo chmod 755 /opt/tomcat/app/conf/setenv.sh
fi

# remove install files
sudo rm -rf /home/ec2-user/tomcat7*
sudo rm -rf /home/ec2-user/PKI/*
sudo rm -rf /home/ec2-user/security/*
sudo rm -rf /home/ec2-user/OTHER/*
sudo rm -rf /home/ec2-user/webapps/*
########## check the app name here ############
#sudo sed -i -e 's/JAVA_OPTS=\"\"/JAVA_OPTS=\"-server -Xms5120m -Xmx5120m -XX:MaxPermSize=1024m -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Dgw.server.mode=dev -Daviva.gw.'$app'.env=AWS -Daviva.gw.'$app'.serverid=AWS -Daviva.gw.'$app'.env.ui='$env_name' -Dcom.ibm.SSL.ConfigURL=file:\/\/\/opt\/tomcat\/app\/conf\/ssl.client.props -Xcompressedrefs -Djavax.net.ssl.trustStore=\/usr\/java\/jdk1.8.0_181\/jre\/lib\/security\/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.keyStore=\/etc\/pki\/client_keystore.jks -Djavax.net.ssl.keyStorePassword=changeit -Djdk.tls.ephemeralDHKeySize=2048 -Dallow.unsigned.sdk.extension.jars=true -Xmn512m -verbose:gc\"/g' $tomhome/bin/setenv.sh
###############################
#do chkconfig tomcat on
sudo firewall-cmd --permanent --zone=public --add-port=8443/tcp
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

# start the service
#sudo systemctl start tomcat
sudo systemctl enable tomcat
# todo - does the tar file contain a PID ? remove it
sudo rm -f /opt/tomcat/app/temp/tomcat.pid
sudo /sbin/runuser -l tomcat -c /opt/tomcat/app/bin/startup.sh

# Install AppDynamics from here for now TODO: consider if better being a separate task

