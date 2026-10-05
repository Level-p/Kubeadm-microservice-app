#creating security for stage
resource "aws_security_group" "stage_sg" {
  name        = "${var.name}-loadbalancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating stage load balancer
resource "aws_lb" "stage_lb" {
  name               = "${var.name}-stage-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.stage_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

#creating stage target group
resource "aws_lb_target_group" "stage_tg" {
  name        = "${var.name}-stage-tg-ip"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

#creating target group attachment for stage load balancer
resource "aws_lb_target_group_attachment" "stage_tg_attachment" {
  count            = length(var.target_ids)
  target_group_arn = aws_lb_target_group.stage_tg.arn
  target_id        = var.target_ids[count.index]
  # port             = 30001     #enable only if you do not prefer the internal loadbalancer (HA-Proxy)
  port = 443
}

#creating stage listener for https load balancer
resource "aws_lb_listener" "stage_listener" {
  load_balancer_arn = aws_lb.stage_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.stage_tg.arn
  }
}

#creating stage listner for http load balancer
resource "aws_lb_listener" "stage_http_listener" {
  load_balancer_arn = aws_lb.stage_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#Creating security group for prod
resource "aws_security_group" "prod_sg" {
  name        = "${var.name}-prod-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating prod load balancer
resource "aws_lb" "prod_lb" {
  name               = "${var.name}-prod-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.prod_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

#creating prod target group
resource "aws_lb_target_group" "prod_tg" {
  name        = "${var.name}-prod-tg-ip"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

#creating target group attachment for prod load balancer
resource "aws_lb_target_group_attachment" "prod_tg_attachment" {
  count            = length(var.target_ids)
  target_group_arn = aws_lb_target_group.prod_tg.arn
  target_id        = var.target_ids[count.index]
  # port             = 30002
  port = 443
}

#creating prod listener for https load balancer
resource "aws_lb_listener" "prod_listener" {
  load_balancer_arn = aws_lb.prod_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_tg.arn
  }
}

#Creating prod listner for http load balancer
resource "aws_lb_listener" "prod_http_listener" {
  load_balancer_arn = aws_lb.prod_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#creating security group for prometheus
resource "aws_security_group" "prometheus_sg" {
  name        = "${var.name}-prometheus-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating prometheus load balancer
resource "aws_lb" "prometheus_lb" {
  name               = "${var.name}-prometheus-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.prometheus_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

#creating prometheus target group
resource "aws_lb_target_group" "prometheus_tg" {
  name        = "${var.name}-prometheus-tg-ip"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

#creating target group attachment for prometheus load balancer
resource "aws_lb_target_group_attachment" "prometheus_tg_attachment" {
  count            = length(var.target_ids)
  target_group_arn = aws_lb_target_group.prometheus_tg.arn
  target_id        = var.target_ids[count.index]
  # port             = 31090
  port = 443
}

#creating prometheus listener for https load balancer
resource "aws_lb_listener" "prometheus_listener" {
  load_balancer_arn = aws_lb.prometheus_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}

#creating prometheus listner for http load balancer
resource "aws_lb_listener" "prometheus_http_listener" {
  load_balancer_arn = aws_lb.prometheus_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#creating security group for grafana
resource "aws_security_group" "grafana_sg" {
  name        = "${var.name}-grafana-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creating grafana load balancer
resource "aws_lb" "grafana_lb" {
  name               = "${var.name}-grafana-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.grafana_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

#creating grafana target group
resource "aws_lb_target_group" "grafana_tg" {
  name        = "${var.name}-grafana-tg-ip"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

#creating target group attachment for grafana load balancer
resource "aws_lb_target_group_attachment" "grafana_tg_attachment" {
  count            = length(var.target_ids)
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = var.target_ids[count.index]
  # port             = 31300
  port = 443
}

#creating grafana listener for https load balancer
resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.grafana_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

#creating grafana listner for http load balancer
resource "aws_lb_listener" "grafana_http_listener" {
  load_balancer_arn = aws_lb.grafana_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#creating hosted 
data "aws_route53_zone" "kubadm_zone" {
  name         = var.domain_name
  private_zone = false
}

#creating route53 record for stage load balancer
resource "aws_route53_record" "stage_lb_record" {
  zone_id = data.aws_route53_zone.kubadm_zone.zone_id
  name    = "stage.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.stage_lb.dns_name
    zone_id                = aws_lb.stage_lb.zone_id
    evaluate_target_health = true
  }
}

#creating route53 record for prod load balancer
resource "aws_route53_record" "prod_lb_record" {
  zone_id = data.aws_route53_zone.kubadm_zone.zone_id
  name    = "prod.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.prod_lb.dns_name
    zone_id                = aws_lb.prod_lb.zone_id
    evaluate_target_health = true
  }
}

#creating route53 record for prometheus load balancer
resource "aws_route53_record" "prometheus_lb_record" {
  zone_id = data.aws_route53_zone.kubadm_zone.zone_id
  name    = "prometheus.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.prometheus_lb.dns_name
    zone_id                = aws_lb.prometheus_lb.zone_id
    evaluate_target_health = true
  }
}

#creating route53 record for grafana load balancer
resource "aws_route53_record" "grafana_lb_record" {
  zone_id = data.aws_route53_zone.kubadm_zone.zone_id
  name    = "grafana.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.grafana_lb.dns_name
    zone_id                = aws_lb.grafana_lb.zone_id
    evaluate_target_health = true
  }
}

