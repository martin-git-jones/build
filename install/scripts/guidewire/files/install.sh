#!/bin/bash  
echo "###########################################"
echo "####"
echo "####    Install tagged WAR file from "
echo "#### http://nexus-pre.avivaaws.com/nexus/content/repositories/guidewire-releases/com/aviva/ukgi/gw/prod-packages" 
echo "###########################################"
# Set the proxy server
export http_proxy=http://uknp-obproxy.avivaaws.com:80
export https_proxy=http://uknp-obproxy.avivaaws.com:80
export NO_PROXY=localhost,127.0.0.1,.via.novonet,.avivagroup.com,.avivaaws.com,.ecs.com,169.254.169.254
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
# Configure AWS access keys
/usr/local/bin/aws configure set aws_access_key_id $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'AccessKeyId' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_secret_access_key $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'SecretAccessKey' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set aws_session_token $(curl --silent http://169.254.169.254/latest/meta-data/iam/security-credentials/guidewire.utilities2 | grep 'Token' | awk '{print $3}' | sed 's/"//g' | sed 's/,//g')
/usr/local/bin/aws configure set default.region $REGION
/usr/local/bin/aws configure set default.output json

# Name of key to retrieve
TAG_NAME=GW_AppURL
# Grab tag value
AppURL=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)
echo "Tag is $AppURL"
TAG_NAME=GW_FileName
# Grab tag value
FILENAME=$(/usr/local/bin/aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$TAG_NAME" --region=$REGION --output=text | cut -f5)

if [[ -z $AppURL ]] ;then
   echo "No AppURL value set"
else
  sudo wget --quiet --no-proxy -O $FILENAME $AppURL
  echo "Moving $FILENAME to ./webapps"
  sudo mv ./$FILENAME /opt/tomcat/app/webapps/
  sudo chown tomcat.tomcat /opt/tomcat/app/webapps/*
  sudo service tomcat restart
fi

exit


   	nexusWarUrlNoBs=${nexusWarUrl//\\/}
   	mkdir -p PolicyCenter/dist/war/
   	wget --quiet --no-proxy -O PolicyCenter/dist/war/pc.war $nexusWarUrlNoBs
 		    
   if $MoveToProdPackage
   	then    
   		warpkg=$(echo $nexusWarUrlNoBs | cut -f15 -d"/")
   		mkdir prodPkg
   		cp PolicyCenter/dist/war/pc.war prodPkg   			
   		mv prodPkg/pc.war prodPkg/$warpkg
   		
   		releaseNo=$(echo $JOB_NAME | cut -f2 -d"-")
   		AppName=$(echo $JOB_NAME | cut -f1 -d"-")
   		
   		Quickfix=$( echo $(echo $warpkg | grep -i -o "quickfix") )
   		
   		if (! [[ -z "$Quickfix" ]] )
   		then
   		  echo "quickfix package found"
   		  AppName=$AppName"_"$Quickfix      
   		fi 
   		
   		nexusProdPkg="http://nexus-pre.avivaaws.com/nexus/content/repositories/guidewire-releases/com/aviva/ukgi/gw/prod-packages"   
   		if wget --spider $nexusProdPkg/$releaseNo/$AppName/$warpkg 2>/dev/null; then
   		   echo "This package already exist in prod package folder"
   		else
   		   echo "This package does not exist in prod package folder"
   		   if wget --spider $nexusProdPkg/$releaseNo/$AppName 2>/dev/null; then
   			  curl -v --request DELETE --user $NEXUS_CONNECT --silent $nexusProdPkg/$releaseNo/$AppName
   		   fi      
   			  
   		  curl -v $nexusProdPkg/$releaseNo/$AppName/ -T "prodPkg/$warpkg"
   		fi  
   	fi
   		
   mkdir -p modules/configuration/plugins/shared/lib
   	cp scripts/DBvalidation/JaxwsClientJarsAws/com.ibm.jaxws.thinclient_7.0.0.jar modules/configuration/plugins/shared/lib/
   	cp scripts/DBvalidation/JaxwsClientJarsAws/xml.jar modules/configuration/plugins/shared/lib/
   	zip -ur PolicyCenter/dist/war/pc.war modules
   	echo "###################"
   	#If loop to check the existency for gw_nontam_web.xml file within the war
   	if [ "`7za l PolicyCenter/dist/war/pc.war WEB-INF/gw_nontam_web.xml | grep gw_nontam_web.xml`" = "" ]
   	then
   		echo "Didnot find gw_nontam_web.xml in WEB-INF folder"
   		#Exit 0 specified explicitly since we are using "Conditional steps" in Build step which would exit 1 by default if the file is not found and this fail the job
   		exit 0
   	else
   		echo "Found gw_nontam_web.xml in WEB-INF folder, need to rename it to web.xml for non-prod environments (except for pre-prod)."
   		7za rn PolicyCenter/dist/war/pc.war WEB-INF/web.xml WEB-INF/gw_tam_web.xml
   		7za rn PolicyCenter/dist/war/pc.war WEB-INF/gw_nontam_web.xml WEB-INF/web.xml
   	fi
   	



chmod 755 *.sh
 ./prepareLogsForMonitor.sh pc
 echo ############################################
 echo #########  Tomcat Stop
 echo ############################################
 sudo systemctl stop tomcat
 


date
 ./shutdownMonitor.sh pc
 sudo systemctl -l status tomcat
 rm -rf /opt/tomcat/app/webapps/pc.war
 rm -rf /opt/tomcat/app/webapps/pc
 rm -rf /opt/tomcat/app/temp/*
 rm -rf /opt/tomcat/app/work/*

Then scp 
source PolicyCenter/dist/war/pc.war
dest webapps/

 ./prepareLogsForMonitor.sh pc
 echo ##############################################################################
 echo ##############################################################################
 echo ##############################################################################
 echo #########  Tomcat Start
 echo ##############################################################################
 echo ##############################################################################
 echo ##############################################################################
 sudo systemctl start tomcat
 while [ "$tomcat_status" != "active" ]
 do
 		echo Waiting for Tomcat service to start....
 		sleep 5
 		tomcat_status=$(sudo systemctl is-active tomcat)
 done
 sudo systemctl status tomcat
 ./startupMonitor.sh pc
				
