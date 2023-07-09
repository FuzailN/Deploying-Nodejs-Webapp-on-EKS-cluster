resource "aws_security_group" "cluster-sg" {
  name        = "${var.prefix}-cluster-sg"
  description = "Adding rule for bastion server access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = -1
    from_port       = 0
    to_port         = 0
    security_groups = [aws_security_group.bastion.id]
  }

  tags = local.common_tags
}

resource "aws_security_group" "bastion" {
  name        = "${var.prefix}-bastion"
  description = "Control bastion inbound and outbound access"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}
