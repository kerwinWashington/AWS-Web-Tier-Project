
resource "aws_autoscaling_group" "asg" {
 #   availability_zones = ["us-east-1a", "us-east-1b"]

   vpc_zone_identifier = aws_subnet.private[*].id #change subnets
   desired_capacity   = 2
   max_size           = 3
   min_size           = 2
   target_group_arns = [aws_lb_target_group.front_end.arn]
   launch_template {
     id      = aws_launch_template.asg-lt.id
     version = "$Latest"
   }
    tag {
    key                 = "Name"
    value               = "Washington"
    propagate_at_launch = true
  }
  depends_on = [ aws_nat_gateway.natgw ]
 }

 # Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "example" {
   count = var.publicSubnetCount
   autoscaling_group_name = aws_autoscaling_group.asg.name
   lb_target_group_arn    = aws_lb_target_group.front_end.arn
 }

resource "aws_lb" "test" {
  name               = "washington-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  # count = var.publicSubnetCount
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = true

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.id
#     prefix  = "test-lb"
#     enabled = true
#   }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "front_end" {
  name        = "washington-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "front_end" {
  # count = var.publicSubnetCount
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}



# # # ### Security Groups ###

### Auto Scaling Group Security Group ###
resource "aws_security_group" "asg-sg" {
  name        = "washington-asg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description     = "TLS from VPC"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]

  }
  ingress {
    description     = "HTTP from VPC"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "washington-asg"
  }
}

### Load Balancer Security Group ###
resource "aws_security_group" "lb-sg" {
  name        = "washington-asg-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "washington-lbsg"
  }
}
