provider "aws" {
  
  region = "us-east-2"
}



# Security Group
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22, 80, 443]
}

resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {
  for_each = var.ingressrules
  iterator = port
    content {
      from_port        = port.value
      to_port          = port.value
      protocol         = "TCP"
      cidr_blocks      = ["0.0.0.0/0"]
    }
}
   egress {
     from_port        = 0
     to_port          = 0
     protocol         = "-1"
     cidr_blocks      = ["0.0.0.0/0"]
   }

  tags = {
    "Terraform" = "true"
  }
}

# resorce block
resource "aws_instance" "jenkins" {
  ami             = "ami-0fa49cc9dc8d62c84"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "praveen"

   provisioner "remote-exec" {
       inline = [
         
         "sudo yum update -y",
         "sudo yum -y install wget",
         "sudo amazon-linux-extras install java-openjdk11 -y",
         "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
         "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
         "sudo yum upgrade -y",
         "sudo yum install jenkins -y",
         "sudo systemctl enable jenkins",
         "sudo systemctl start jenkins",
         "sudo systemctl status jenkins",

       ]
   }

    connection {
        type        = "ssh"
        host        = self.public_ip
        user        = "ec2-user"
        private_key = file("praveen.pem")
    }

    tags = {
        "Name"      = "Jenkins Master"
          }

    }

    output "jenkinsinstance_public_ip" {
     description = "Public Ip address of the EC2 instance"
     value       = aws_instance.jenkins.public_ip
    }