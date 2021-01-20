provider "aws" {
  region = "us-east-1"
}

locals {
  instance_type = "t2.medium"
}
resource "aws_lb" "test" {
  name                       = "test-lb-tf"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = ["sg-029795xxxxx"]
  subnets                    = ["subnet-09e18ddxxxx", "subnet-04375955xxx"]
  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "test" {
  name        = "tf-example-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "vpc-01fc1e8db6a2fdbd3"
  health_check {
    enabled  = true
    interval = 10
    path     = "/index.html"
    port     = 80
    protocol = "HTTP"
    matcher  = "200-399"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = ("[aws_instance.web.[*].id]")
  #target_id        = ("[for instance in aws_instance.web : instance.id]")
  port = 80
}

resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0be2609ba883822ec"
  instance_type = local.instance_type == "t2.medium" ? true : var.instance_type

  tags = { Name = "Test ${count.index + 1}"
  }
}
locals {
  ingress_rule = [{
    port        = 443
    description = "https"
    protocol    = "tcp"
    },
    {
      port        = 22
      description = "SSH"
      protocol    = "tcp"
  }]
}
resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  dynamic "ingress" {
    for_each = local.ingress_rule

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"
}
