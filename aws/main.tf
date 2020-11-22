# EC2 instance
resource "aws_instance" "my-instance1" {
  ami           = var.ami_id
  instance_type = var.aws_instance_type
  subnet_id = aws_subnet.my-subnet1-1.id
  tags = {
    Name = var.aws_instance_tag_name
  }
}

#Elastic ip
resource "aws_eip" "my-instance1-eip" {
  instance = aws_instance.my-instance1.ip
  vpc      = true
}

# EC2 load_balancer
resource "aws_alb" "my-alb" {
  name            = "${var.stage}-my-alb"
  internal        = false
  security_groups = aws_security_group.alb.id
  subnets         = aws_subnet.my_subnet1_1.id

  enable_deletion_protection = true

  tags = {
    Environment = var.stage
  }
  access_logs {
    bucket  = module.s3.alb-logs.bucket
    prefix  = "test-${var.stage}-alb"
    enabled = true
  }
}

# EC2 target_group
resource "aws_alb_target_group" "my-target-group1" {
  name                 = "${var.stage}-my-app"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.my-vpc1.id
  deregistration_delay = 30

  health_check {
    interval            = 60
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 20
    unhealthy_threshold = 10
    matcher             = 200
  }
}

# target_group_attachment
resource "aws_alb_target_group_attachment" "alb" {
  count            = 2
  target_group_arn = "${element(aws_alb_target_group.my-target-group1.*.arn, count.index)}"
  target_id        = "${element(aws_instance.my-instance1.id, count.index)}"
  port             = 80
}

# EC2 alb_listener
resource "aws_alb_listener" "my-alb-listener" {
  load_balancer_arn = aws_alb.test.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = aws_acm_certificate.test.arn

  default_action {
    target_group_arn = aws_alb_target_group.test-app.arn
    type             = "forward"
  }
}
