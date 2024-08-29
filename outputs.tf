output "master_ami" {
  value = local.master_ami
}

output "node_ami" {
  value = local.node_ami
}

output "master_node_0_id" {
  value = aws_instance.k3s_master[0].id
}

output "node_pool_asg_name" {
  value = aws_autoscaling_group.node_pool.name
}