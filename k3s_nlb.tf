resource "aws_lb" "k3s_nlb" {
  name               = "${local.cluster_id}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = local.private_subnets
  enable_deletion_protection = false

  tags = {
    Name = "${local.cluster_id}-nlb"
  }
}

resource "aws_lb_target_group" "k3s_nlb_target_group" {
  name     = "${local.cluster_id}-nlb-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = "6443"
  }

  tags = {
    Name = "${local.cluster_id}-nlb-tg"
  }
}

resource "aws_lb_target_group_attachment" "k3s_master_attachment" {
  count            = local.master_count
  target_group_arn = aws_lb_target_group.k3s_nlb_target_group.arn
  target_id        = element(aws_instance.k3s_master.*.id, count.index)
  port             = 6443
}

resource "aws_lb_listener" "k3s_nlb_listener" {
  load_balancer_arn = aws_lb.k3s_nlb.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k3s_nlb_target_group.arn
  }
}

resource "aws_security_group_rule" "allow_nlb_to_master" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  security_group_id = aws_security_group.master_sg.id
  source_security_group_id = aws_lb.k3s_nlb.security_groups[0]
}