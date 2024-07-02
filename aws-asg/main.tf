# AWS KEY-Pair Data Source (Update)
data "aws_key_pair" "EC2-Key" {
  key_name = "EC2-key"
}

resource "aws_launch_configuration" "aws_asg_launch" {
  name            = "${var.name}-asg-launch"
  image_id        = "ami-0ea4d4b8dc1e46212"
  instance_type   = var.instance_type
  key_name        = data.aws_key_pair.EC2-Key.key_name # (Update)
  security_groups = [var.SSH_SG_ID, var.HTTP_HTTPS_SG_ID]

  user_data = <<-EOF
    #!/bin/bash
    yum -y update
    yum -y install httpd.x86_64
    systemctl start httpd.service
    systemctl enable httpd.service
    echo "DB Endpoint: ${data.terraform_remote_state.rds_remote_data.outputs.rds_instance_address}" > /var/www/html/index.html
    echo "DB Port: ${data.terraform_remote_state.rds_remote_data.outputs.rds_instance_port}" >> /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

# AutoScaling Policy ( Scale-OUT ) (Update)
resource "aws_autoscaling_policy" "aws_asg_policy_out" {
  name                   = "${var.name}-asg-policy-out"
  adjustment_type        = "ChangeInCapacity"     # 용량 변경 정책
  scaling_adjustment     = 1                      # Scaling 수 지정 (1개 증가)
  cooldown               = 120                    # 재 조정 대기시간 ( 120초 )
  autoscaling_group_name = aws_autoscaling_group.aws_asg.name # AutoScaling Policy 적용 대상지정
}


resource "aws_cloudwatch_metric_alarm" "aws_asg_cpu_alarm_out" {
  alarm_name          = "aws_asg_cpu_alarm_Scale Out"
  metric_name         = "CPUUtilization"                  # CPU 사용률
  statistic           = "Average"                         # CPU 평균 사용률 체크
  period              = 60                                # CPU 평균 사용률 체크 주기 (60초)
  namespace           = "AWS/EC2"                         # CPU 평균 사용률 수집 범위 (EC2)
  threshold           = 70                                # 비교 대상 값 지정
  comparison_operator = "GreaterThanOrEqualToThreshold"   # 비교 연산자 (70% >= 평균 사용률)
  evaluation_periods  = 2                                 # 2번 연속 지정 된 사용률을 초과할 경우 Scale-Out
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.aws_asg.name # CloudWatch가 적용 될 Resource 지정
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.aws_asg_policy_out.arn] 
  # 비교 연산자의 조건을 만족했을때 수행 할 작업정의
}


# AutoScaling Policy ( Scale-IN ) (Update)
resource "aws_autoscaling_policy" "aws_asg_policy_in" {
  name                   = "${var.name}-asg-policy-in"
  adjustment_type        = "ChangeInCapacity"     # 용량 변경 정책
  scaling_adjustment     = -1                     # Scaling 수 지정 (1개 감소)
  cooldown               = 120                    # 재 조정 대기시간 ( 120초 )
  autoscaling_group_name = aws_autoscaling_group.aws_asg.name # AutoScaling Policy 적용 대상지정
}


resource "aws_cloudwatch_metric_alarm" "aws_asg_cpu_alarm_in" {
  alarm_name          = "aws_asg_cpu_alarm_Scale In"
  metric_name         = "CPUUtilization"                  # CPU 사용률
  statistic           = "Average"                         # CPU 평균 사용률 체크
  period              = 60                                # CPU 평균 사용률 체크 주기 (60초)
  namespace           = "AWS/EC2"                         # CPU 평균 사용률 수집 범위 (EC2)
  threshold           = 10                                # 비교 대상 값 지정
  comparison_operator = "LessThanOrEqualToThreshold"      # 비교 연산자 (10% <= 평균 사용률)
  evaluation_periods  = 2                                 # 2번 연속 지정 된 사용률을 초과할 경우 Scale-Out
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.aws_asg.name # CloudWatch가 적용 될 Resource 지정
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.aws_asg_policy_in.arn] 
  # 비교 연산자의 조건을 만족했을때 수행 할 작업정의
}

resource "aws_autoscaling_group" "aws_asg" {
  name                 = "${var.name}-asg"
  launch_configuration = aws_launch_configuration.aws_asg_launch.name
  desired_capacity     = var.desired_size # (Update)
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = var.private_subnets

  target_group_arns = [data.terraform_remote_state.alb_remote_data.outputs.ALB_TG] # (Update)
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.name}-Terraform_Instance"
    propagate_at_launch = true
  }
}