data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "jenkins" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t2.medium"
  subnet_id            = aws_subnet.public_a.id
  key_name             = var.server_key_name

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-jenkins"}),
    tomap({"server" = "jenkins"})
  )

  provisioner "local-exec" {
    command = "echo url='https://www.duckdns.org/update?domains=jenkins-server&token=${var.duckdns_token}&ip=${aws_instance.jenkins.public_ip}' | curl -K -"
  }
}

resource "aws_instance" "nexus" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t2.medium"
  subnet_id            = aws_subnet.public_a.id
  key_name             = var.server_key_name

  vpc_security_group_ids = [
    aws_security_group.nexus.id
  ]

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-nexus"}),
    tomap({"server" = "nexus"})
  )

  provisioner "local-exec" {
    command = "echo url='https://www.duckdns.org/update?domains=nexus-server&token=${var.duckdns_token}&ip=${aws_instance.nexus.public_ip}' | curl -K -"
  }
}

resource "aws_instance" "nginx" {
  ami                  = data.aws_ami.amazon_linux.id
  instance_type        = "t2.medium"
  subnet_id            = aws_subnet.public_a.id
  key_name             = var.server_key_name

  vpc_security_group_ids = [
    aws_security_group.nginx.id
  ]

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-nginx"}),
    tomap({"server" = "nginx"})
  )

  provisioner "local-exec" {
    command = "echo url='https://www.duckdns.org/update?domains=nginx-proxy&token=${var.duckdns_token}&ip=${aws_instance.nginx.public_ip}' | curl -K -"
  }
}

resource "null_resource" "jenkins" {
  triggers = {
    trigger = aws_instance.jenkins.public_ip
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "local-exec" {
    working_dir = "../Ansible"
    command = "ansible-playbook Jenkins/jenkins.yaml"
  }
}

resource "null_resource" "nexus" {
  triggers = {
    trigger = aws_instance.nexus.public_ip
  }
  
  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "local-exec" {
    working_dir = "../Ansible"
    command = "ansible-playbook Nexus/nexus.yaml"
  }
}

resource "null_resource" "nginx" {
  depends_on = [
      null_resource.jenkins,
      null_resource.nexus
    ]

  provisioner "local-exec" {
    working_dir = "../Ansible"
    command = "ansible-playbook Nginx/nginx.yaml"
  }
}

resource "null_resource" "Initial_passwords" {
  triggers = {
    trigger = null_resource.nginx.id
  }

  provisioner "local-exec" {
    working_dir = "../Ansible"
    command = "ansible-playbook Initial-passwords/initial_passwords.yaml"
  }
}