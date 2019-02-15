#!/bin/bash

tomcat() {
sudo ps aux | grep tomcat
}
alias tomcat=tomcat

tomcatstart() {
sudo service tomcat start
}
alias tomcatstart=tomcatstart

tomcatstop() {
sudo service tomcat stop
}
alias tomcatstop=tomcatstop

tomcatdir() {
cd /opt/tomcat/app/
}
alias tomcatdir=tomcatdir
