// TODO Should this is target by ip?
// TODO At the moment everything is using on security group - divide this up.
resource "aws_lb_target_group" "cudl-content-loader-lb-target-group" {
  health_check {
    interval = 30
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 2
    healthy_threshold = 5
    matcher = "200"
  }
  port = 8081
  protocol = "HTTP"
  #target_type = "ip"
  target_type = "instance"
  vpc_id = aws_vpc.cudl-content-loader-vpc.id
  name = "${var.environment}-cudl-lb-tar"
  depends_on = [
    aws_vpc.cudl-content-loader-vpc
  ]
}

// TODO security group
resource "aws_lb" "cudl-content-elastic-load-balancer" {
  name = "${var.environment}-cudlloadbalancer"
  internal = false
  load_balancer_type = "application"
  subnets = [
    aws_subnet.cudl-content-loader-ec2-subnet-public1.id,
    aws_subnet.cudl-content-loader-ec2-subnet-public2.id
  ]
  security_groups = [
    aws_security_group.cudl-loader-security-group.id
  ]
  ip_address_type = "ipv4"
  access_logs {
    enabled = false
    bucket = ""
    prefix = ""
  }
  idle_timeout = "60"
  enable_deletion_protection = "false"
  enable_http2 = "true"
  enable_cross_zone_load_balancing = "true"
  depends_on = [
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_subnet.cudl-content-loader-ec2-subnet-public2,
    aws_security_group.cudl-loader-security-group
  ]
}

resource "aws_lb_listener" "cudl-loader-elastic-load-balancing-listener" {
  tags = {
    Name = "${var.environment}-cudl-elb-listener"
  }
  load_balancer_arn = aws_lb.cudl-content-elastic-load-balancer.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate.cudl-certificate-default.arn
  default_action {
    target_group_arn = aws_lb_target_group.cudl-content-loader-lb-target-group.arn
    type = "forward"
  }
  depends_on = [
    aws_lb.cudl-content-elastic-load-balancer,
    aws_acm_certificate.cudl-certificate-default,
    aws_lb_target_group.cudl-content-loader-lb-target-group
  ]
}

resource "aws_network_interface" "cudl-loader-ec2-elb-network-interface" {
  tags = {
    Name = "${var.environment}-cudl-elb-ni"
  }
  description = "ELB app/${aws_lb.cudl-content-elastic-load-balancer.name}/${aws_lb.cudl-content-elastic-load-balancer.id}"
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public2.id
  source_dest_check = true
  security_groups = [
    aws_security_group.cudl-loader-security-group.id
  ]
  depends_on = [
    aws_lb.cudl-content-elastic-load-balancer,
    aws_subnet.cudl-content-loader-ec2-subnet-public2,
    aws_security_group.cudl-loader-security-group
  ]
}

resource "aws_network_interface" "cudl-loader-ec2-elb-network-interface2" {
  tags = {
    Name = "${var.environment}-cudl-elb-ni2"
  }
  description = "ELB app/${aws_lb.cudl-content-elastic-load-balancer.name}/${aws_lb.cudl-content-elastic-load-balancer.id}"
  subnet_id = aws_subnet.cudl-content-loader-ec2-subnet-public1.id
  source_dest_check = true
  security_groups = [
    aws_security_group.cudl-loader-security-group.id
  ]
  depends_on = [
    aws_lb.cudl-content-elastic-load-balancer,
    aws_subnet.cudl-content-loader-ec2-subnet-public1,
    aws_security_group.cudl-loader-security-group
  ]
}