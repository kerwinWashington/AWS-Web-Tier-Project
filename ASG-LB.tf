resource "aws_autoscaling_group" "asg" {
   vpc_zone_identifier = aws_subnet.private[*].id
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
  subnets            = aws_subnet.public[*].id
  enable_deletion_protection = true
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
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

# # # ### Security Groups ### # # #

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
  }
  tags = {
    Name = "washington-lbsg"
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale-up" {
  name = "washington-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

# Scale Up Alarm
resource "aws_cloudwatch_metric_alarm" "sacle-up-alarm" {
  alarm_name = "washington-scale-up-alarm"
  alarm_description = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"
  dimensions = {
    "AutoScailingGroupName" = aws_autoscaling_group.asg.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-up.arn]
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale-down" {
  name = "washington-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "-1"
  cooldown = "300"
  policy_type = "SimpleScaling"
}

# Scale Down Alarm
resource "aws_cloudwatch_metric_alarm" "sacle-down-alarm" {
  alarm_name = "washington-scale-down-alarm"
  alarm_description = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "30"
  dimensions = {
    "AutoScailingGroupName" = aws_autoscaling_group.asg.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.scale-down.arn]
}
