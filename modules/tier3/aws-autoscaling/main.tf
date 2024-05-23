
# Creating Launch template for App tier AutoScaling Group!
resource "aws_launch_template" "App-lunchConfig" {
  name = "App-template"
  image_id = var.ami-id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance-profile-name
  }

  vpc_security_group_ids = [var.app-securityGroup-id]
  
  user_data = base64encode(templatefile("${path.module}/app_userdata.sh", {
  }))
}


resource "aws_autoscaling_group" "App-ASG" {
  name = var.app-autoScalingGroup-name
  vpc_zone_identifier  = [data.aws_subnet.private-subnet1.id, data.aws_subnet.private-subnet2.id]
  launch_template {
    id = aws_launch_template.App-lunchConfig.id
    version = aws_launch_template.App-lunchConfig.latest_version
  }
  min_size             = 2
  max_size             = 4
  health_check_type    = "ELB"
  health_check_grace_period = 300
  target_group_arns    = [var.app-targetGroup-arn]
  force_delete         = true

  tag {
    key                 = "Name"
    value               = "App-ASG"
    propagate_at_launch = true
  }

}


resource "aws_autoscaling_policy" "app-custom-cpu-policy" {
  name                   = "custom-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.Web-ASG.id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}


resource "aws_cloudwatch_metric_alarm" "app-custom-cpu-alarm" {
  alarm_name          = "custom-webserver-cpu-alarm"
  alarm_description   = "alarm when cpu usage increases"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.Web-ASG.name
  }
  actions_enabled = true

  alarm_actions = [aws_autoscaling_policy.web-custom-cpu-policy.arn]
}


resource "aws_autoscaling_policy" "app-custom-cpu-policy-scaledown" {
  name                   = "custom-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.Web-ASG.id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "app-custom-cpu-alarm-scaledown" {
  alarm_name          = "custom-webserver-cpu-alarm-scaledown"
  alarm_description   = "alarm when cpu usage decreases"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.App-ASG.name
  }
  actions_enabled = true

  alarm_actions = [aws_autoscaling_policy.app-custom-cpu-policy-scaledown.arn]
}


# Creating Launch template for Web tier AutoScaling Group!
resource "aws_launch_template" "Web-lunchConfig" {
  name = "Web-template"
  image_id = var.ami-id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance-profile-name
  }

  vpc_security_group_ids = [var.web-securityGroup-id]

  user_data = base64encode(templatefile("${path.module}/web_userdata.sh", {
    app-lb-dns = var.app-alb-dns-name
  }))


  depends_on = [ aws_autoscaling_group.App-ASG ]
}


resource "aws_autoscaling_group" "Web-ASG" {
  name = var.web-autoScalingGroup-name
  vpc_zone_identifier  = [data.aws_subnet.private-subnet1.id, data.aws_subnet.private-subnet2.id]
  launch_template {
    id = aws_launch_template.Web-lunchConfig.id
    version = aws_launch_template.Web-lunchConfig.latest_version
  }
  min_size             = 2
  max_size             = 4
  health_check_type    = "ELB"
  health_check_grace_period = 300
  target_group_arns    = [var.web-targetGroup-arn]
  force_delete         = true
  tag {
    key                 = "Name"
    value               = "Web-ASG"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "web-custom-cpu-policy" {
  name                   = "custom-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.Web-ASG.id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}


resource "aws_cloudwatch_metric_alarm" "web-custom-cpu-alarm" {
  alarm_name          = "custom-webserver-cpu-alarm"
  alarm_description   = "alarm when cpu usage increases"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.Web-ASG.name
  }
  actions_enabled = true

  alarm_actions = [aws_autoscaling_policy.web-custom-cpu-policy.arn]
}


resource "aws_autoscaling_policy" "web-custom-cpu-policy-scaledown" {
  name                   = "custom-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.Web-ASG.id
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "web-custom-cpu-alarm-scaledown" {
  alarm_name          = "custom-webserver-cpu-alarm-scaledown"
  alarm_description   = "alarm when cpu usage decreases"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    "AutoScalingGroupName" : aws_autoscaling_group.Web-ASG.name
  }
  actions_enabled = true

  alarm_actions = [aws_autoscaling_policy.web-custom-cpu-policy-scaledown.arn]
}