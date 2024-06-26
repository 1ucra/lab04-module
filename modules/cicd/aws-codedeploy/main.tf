resource "aws_iam_role" "hellowaws-codedeploy-role" {
  name = "hellowaws_codedeploy_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy-role-policy" {
  role       = aws_iam_role.hellowaws-codedeploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_role_policy_attachment" "admin-access-policy" {
  role       = aws_iam_role.hellowaws-codedeploy-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codedeploy_app" "hellowaws-app-deploy" {
  name             = "hellowaws_app_deploy"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "app-deploy-group" {
  app_name              = aws_codedeploy_app.hellowaws-app-deploy.name
  deployment_group_name = "first_app_deploy_group"
  service_role_arn      = aws_iam_role.hellowaws-codedeploy-role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 1  # 기존 인스턴스 종료 전에 대기하는 시간 (단위: 분)
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    green_fleet_provisioning_option {
      action = "COPY_AUTO_SCALING_GROUP"
    }
  }

  load_balancer_info {
    target_group_info {
      name = var.app_targetGroupName
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  autoscaling_groups = [
    var.app_autoscalingGroupName,
  ]
}
