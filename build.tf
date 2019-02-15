variable "user" {
        type = "string"
        default = ""
}

variable "pass" {
        type = "string"
        default = ""
}

variable "token_gw" {
        type = "string"
        default = ""
}


# INSTANCE DETAILS

variable "source_ami" {
        type = "string"
        default = ""
}

variable "env_name" {
        type = "string"
        default = "HOSTNAME"
}

variable "vpc_id" {
        type = "string"
        default = "vpc-a407d9c1"
}

variable "environment_purpose" {
        type = "string"
        default = "ENVIRONMENTPURPOSE"
}

variable "availability_zone" {
        type = "string"
        default = "AVAILABILITYZONE"
}

variable "creator_tag" {
        type = "string"
        default = "GW.Development.Support@aviva.co.uk"
}

# INSTANCE DESCRIPTION

variable "region" {
        type = "string"
        default = "eu-west-1"
}
variable "instance_type" {
        type = "string"
        default = "m4.large"
}

variable "iam_instance_profile" {
        type = "string"
        default = "guidewire.utilities2"
}
variable "security_group_ids" {
        type = "list"
        default = ["sg-6fd6bf0a","sg-f10e2b94"]
}

variable "subnet_ids" {
        type = "list"
        default = ["subnet-777bef12", "subnet-86f64af1", "subnet-83f64af4"]
}


# INSTANCE TAGS
variable "AWSName" {
        type = "string"
        default = "AWSNAME"
}
variable "created_tag" {
        type = "string"
        default = ""
}
variable "cost_centre_tag" {
        type = "string"
        default = "COSTCENTRE"
}

variable "environment_tag" {
        type = "string"
        default = "Common_NonProduction"
}
variable "expiry_tag" {
        type = "string"
        default = "9999-12-31"
}
variable "hsn_tag" {
        type = "string"
        default = "HSNTAG"
}
variable "owner_tag" {
        type = "string"
        default = "GW.Development.Support@aviva.co.uk"
}
variable "schedule_tag" {
        type = "string"
        default = "YSun0000-0000Mon0700+1900Tue0700+1900Wed0700+1900Thu0700+1900Fri0700+1900Sat0000-0000"
}
variable "private_ip" {
        type = "string"
        default = "PRIVATEIP"
}

# END OF VARIABLES

provider "aws" {
  access_key = "${var.user}"
  secret_key = "${var.pass}"
  token = "${var.token_gw}"
  region     = "${var.region}"
}


resource "aws_instance" "GW_Linux_Demo_TestOnly" {
  ami = "${var.source_ami}"
  availability_zone = "${var.availability_zone}"
  instance_type = "${var.instance_type}"
  security_groups = "${var.security_group_ids}"
  key_name = "gw-devops-feb18"
  private_ip = "${var.private_ip}"
  subnet_id = "SUBNET"
  iam_instance_profile = "${var.iam_instance_profile}"
  associate_public_ip_address = "false"
  #provisioner "local-exec" {
  #  command    = "sudo yum-config-manager --disable PULP_RHEL7 ;"
  #   wget -O /tmp/epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; rpm -i /tmp/epel-release-latest-7.noarch.rpm; yum install -y update; yum install -y ansible"
  #  on_failure = "continue"
  #}

 
  tags {
    Costcentre_Projectcode = "${var.cost_centre_tag}"
    Creator = "${var.creator_tag}"
    Environment_Purpose = "${var.environment_purpose}"
    Environment = "${var.environment_tag}"
    Expiry = "${var.expiry_tag}"
    HSN = "${var.hsn_tag}"
    Name = "${var.AWSName}"
    Owner = "${var.owner_tag}"
    Created = "${var.created_tag}"
    Schedule = "${var.schedule_tag}"
    GWEnvName = "${var.env_name}"
    GW_JavaVersion = "JAVAVERSION"
    GW_TomcatVersion = "TOMCATVERSION"
    GW_DeployApp = "DEPLOYAPP"
    GW_WarURL = "WARURL"
    GW_AppName = "APPNAME"
    Hostname = "HOSTNAME"
    GW_CommitHash = "COMMITHASH"
  }
     
                    
}
