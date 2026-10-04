output "lb_security_group_ids" {
  value = [
    aws_security_group.stage_sg.id,
    aws_security_group.prod_sg.id,
    aws_security_group.prometheus_sg.id,
    aws_security_group.grafana_sg.id,
  ]
}
