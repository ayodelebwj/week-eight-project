#============================================
#Provision Java AMI Template
#============================================


#================================================================
#RETRIEVES UBUNTU AMI FROM AWS STORE TO PROVISION AMI TEMPLATE VM
#================================================================
data "amazon-parameterstore" "java_ubuntu_params" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

#================================================================
#CREATES THE INSTANCE NEEDED TO BUILD AMI AND CREATE A TEMPLATE
#================================================================
#Creates the instance to build AMI off it
source "amazon-ebs" "java-vm-source" {
  region          = "us-east-2"
  instance_type   = "t3.micro"
  ssh_username    = "ubuntu"
  source_ami    = data.amazon-parameterstore.java_ubuntu_params.value
  ami_name        = "java-ami"
}

#================================================================
#BUILDS THE JAVA AMI TEMPLATE
#================================================================
build {
  name    = "java-build"
  sources = ["source.amazon-ebs.java-vm-source"]

  provisioner "shell" {
    inline_shebang = "/bin/bash -xe"
    inline = [
      "sudo apt update -y",
      "sudo apt install openjdk-17-jdk -y",
      "sudo apt install maven -y",
      "exit 0"
    ]
  }
}
