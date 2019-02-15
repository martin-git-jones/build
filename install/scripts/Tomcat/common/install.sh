#!/bin/bash
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
TAG_NAME=GW_JavaVersion
# Grab tag value
JavaVersion=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
if [[ $JavaVersion == "Oracle_1_8_Latest" ]]; then
   javahomepath="/usr/java/jdk1.8.0_181"
fi
if [[ $JavaVersion == "ibm_1_6" ]]; then
   javahomepath="/usr/java/ibm-java-x86_64-60"
fi


#/usr/local/bin/aws s3 cp s3://avivauknonprod/applications/guidewire/backups/certs/AvivaGroupInternalRootCA.cer ~/certs/
tomhome="/opt/tomcat/app"
ec2home="/home/ec2-user"
datasource="$tomhome/conf/Catalina/localhost"
jkscert="$tomhome/jkscerts"
logdir="/usr/WSApps"
sshkey="$tomhome/.ssh"

directories=( $datasource $jkscert $logdir $sshkey )
for dir in "${directories[@]}"
do
sudo mkdir -p $dir
sudo chown -R tomcat:tomcat $dir
sudo chmod -R 755 $dir
done
if [ "$app" == "PC2" ]; then
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/config/PC
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/logs
elif [ "$app" == "PC" ]; then
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/config/PC
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/logs
elif [ "$app" == "CC" ]; then
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/config/CC
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/logs
else 
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/config/CM
	sudo mkdir -p $tomhome/UKGG$app/Guidewire/logs
fi
sudo ln -s $tomhome/UKGG"$app" $logdir/UKGG"$app"
sudo mv $tomhome/webapps/docs $tomhome/webapps/docs1
sudo mv $tomhome/webapps/ROOT $tomhome/webapps/ROOT1
logreader="http://nexus-pre.avivaaws.com/nexus/content/repositories/guidewire-releases/com/aviva/ukgi/gw/files/logreader.war"
sqljar="http://nexus-pre.avivaaws.com/nexus/content/repositories/guidewire-releases/com/aviva/ukgi/gw/files/ojdbc7-12.1.0.2.0-prod.jar"
sudo wget -P $tomhome/webapps/ "$logreader"
sudo wget -P $tomhome/lib/ "$sqljar"
sudo chown -R tomcat:tomcat /home/apps /opt/tomcat
sudo chmod -R 755 /home/apps /opt/tomcat
sudo cp $ec2home/.ssh/authorized_keys $tomhome/.ssh
sudo sed -i '/^common.loader/ s|$|,/usr/WSApps/UKGGPC/Guidewire/config/PC,/usr/WSApps/UKGGCC/Guidewire/config/CC,/usr/WSApps/UKGGCM/Guidewire/config/CM|' /opt/tomcat/app/conf/catalina.properties
sudo cp $ec2home/tomcat-users.xml $tomhome/conf
sudo cp $ec2home/server.xml $tomhome/conf
sudo cp $ec2home/setenv.sh $tomhome/bin
sudo cp $ec2home/web.xml $tomhome/conf

sudo cp $ec2home/setenv.sh $tomhome/bin
sudo sed -i -e 's/JAVA_OPTS=\"\"/JAVA_OPTS=\"-server -Xms5120m -Xmx5120m -XX:MaxPermSize=1024m -Djava.net.preferIPv4Stack=true -Djava.awt.headless=true -Dgw.server.mode=dev -Daviva.gw.'$app'.env=AWS -Daviva.gw.'$app'.serverid=AWS -Daviva.gw.'$app'.env.ui='$env_name' -Dcom.ibm.SSL.ConfigURL=file:\/\/\/opt\/tomcat\/app\/conf\/ssl.client.props -Xcompressedrefs -Djavax.net.ssl.trustStore=\/usr\/java\/jdk1.8.0_181\/jre\/lib\/security\/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.keyStore=\/etc\/pki\/client_keystore.jks -Djavax.net.ssl.keyStorePassword=changeit -Djdk.tls.ephemeralDHKeySize=2048 -Dallow.unsigned.sdk.extension.jars=true -Xmn512m -verbose:gc\"/g' $tomhome/bin/setenv.sh
sudo firewall-cmd --reload
sudo chkconfig tomcat on


sudo chkconfig tomcat on
sudo firewall-cmd --permanent --zone=public --add-port=8443/tcp
sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp
sudo firewall-cmd --reload

