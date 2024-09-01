resource "aws_security_group" "self" {
  name        = "${local.cluster_id}-self"
  vpc_id      = data.aws_vpc.this.id
  description = "Allow all members of this SG to inter-communicate"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags = {
    "kubernetes.io/cluster/${local.cluster_id}" = "owned"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_security_group" "node_ports" {
  name        = "${local.cluster_id}-node-ports"
  vpc_id      = data.aws_vpc.this.id
  description = "Allow node ports to be discovered"

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]  # Allow node port access only within the VPC
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]  # Allow kubelet API access only within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${local.cluster_id}-node-ports"
  }
}

resource "aws_security_group" "egress" {
  name        = "${local.cluster_id}-egress"
  vpc_id      = data.aws_vpc.this.id
  description = "Allow unbounded egress communication"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${local.cluster_id}-egress"
  }
}

resource "aws_security_group" "master_sg" {
  name        = "${local.cluster_id}-master"
  vpc_id      = data.aws_vpc.this.id
  description = "Security group for k3s master nodes"


  ingress {
    from_port         = 10250
    to_port           = 10250
    protocol          = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]  # Allow kubelet API access only within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${local.cluster_id}-master"
  }
}

resource "aws_security_group" "nlb" {
  name        = "${local.cluster_id}-nlb-sg"
  vpc_id      = data.aws_vpc.this.id
  description = "Security group for the NLB"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.trusted_ip_ranges  # Use the trusted_ips variable as trusted IP ranges
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    security_groups = [aws_security_group.node_ports.id, aws_security_group.self.id]  # Allow from node and self security groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${local.cluster_id}-nlb-sg"
  }
}

resource "aws_security_group" "node_sg" {
  name        = "${local.cluster_id}-node-sg"
  vpc_id      = data.aws_vpc.this.id
  description = "Security group for k3s nodes"

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]  # Allow kubelet API access only within the VPC
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]  # Allow node ports access only within the VPC
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block] # Allow Kubernetes API access only within the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "${local.cluster_id}-node-sg"
  }
}