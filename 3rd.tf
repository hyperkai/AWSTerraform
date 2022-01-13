/*# Route53 Record
resource "aws_route53_record" "rec0" {
  zone_id = aws_route53_zone.zone0.zone_id
  name    = var.domain
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = aws_lb.lb0.dns_name
    zone_id                = aws_lb.lb0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "rec1" {
  zone_id = aws_route53_zone.zone0.zone_id
  name    = var.domain
  type    = "AAAA"
  allow_overwrite = true
  
  alias {
    name                   = aws_lb.lb0.dns_name
    zone_id                = aws_lb.lb0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "rec2" {
  zone_id = aws_route53_zone.zone0.zone_id
  name    = var.subdomain
  type    = "A"
  allow_overwrite = true
  
  alias {
    name                   = aws_lb.lb0.dns_name
    zone_id                = aws_lb.lb0.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "rec3" {
  zone_id = aws_route53_zone.zone0.zone_id
  name    = var.subdomain
  type    = "AAAA"
  allow_overwrite = true
  
  alias {
    name                   = aws_lb.lb0.dns_name
    zone_id                = aws_lb.lb0.zone_id
    evaluate_target_health = true
  }
}

# Load Balancer
resource "aws_lb" "lb0" {
  name               = "lb0"
  internal           = false
  #ip_address_type    = "ipv4"
  ip_address_type    = "dualstack"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.pubSg0.id]
  subnets            = [aws_subnet.pubSn0.id, aws_subnet.pubSn1.id]
}

# Load Balancer Target Group
resource "aws_lb_target_group" "lbTg0" {
  name     = "lbTg0"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc0.id

  health_check {
    path = "/healthCheck"
    port = 80
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = "200"
  }
}

resource "aws_lb_target_group" "lbTg1" {
  name     = "lbTg1"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.vpc0.id

  health_check {
    path = "/healthCheck"
    port = 80
    healthy_threshold = 3
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = "200"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "lbLis0" {
  load_balancer_arn = aws_lb.lb0.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbTg0.arn
  }
}

resource "aws_lb_listener" "lbLis1" {
  load_balancer_arn = aws_lb.lb0.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.acv0.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbTg0.arn
  }
}

resource "aws_lb_listener" "lbLis2" {
  load_balancer_arn = aws_lb.lb0.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lbTg1.arn
  }
}

# Load Balancer Listener Rule
resource "aws_lb_listener_rule" "lbLisRule0" {
  listener_arn = aws_lb_listener.lbLis0.arn

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = var.subdomain
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values           = [var.domain, var.subdomain]
    }
  }
}

resource "aws_lb_listener_rule" "lbLisRule1" {
  listener_arn = aws_lb_listener.lbLis1.arn

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      port        = "443"
      host        = var.subdomain
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values           = [var.domain]
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "ecsClu0" {
  name = "ecsClu0"
  depends_on = [aws_lb.lb0]
}

# CloudWatch Log Group for ECS Task Definition
resource "aws_cloudwatch_log_group" "cwlg0" {
  name = "/ecs/ecsTd0"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ecsTd0" {
  family                   =  "ecsTd0"
  task_role_arn            = aws_iam_role.iamRole0.arn
  execution_role_arn       = aws_iam_role.iamRole0.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "1GB"
  cpu                      = "0.5 vCPU"
  
  container_definitions = jsonencode([
    {
      name      = "web"
      image     = var.webImg
      portMappings = [
        {
          containerPort = 80
          protocol = "tcp"
          hostPort      = 80
        }
      ]
      essential = true
      dependsOn = [
          {
              containerName = "app",
              condition = "HEALTHY"
          }
      ]
      logConfiguration = {
          logDriver = "awslogs"
          options = {
              awslogs-group = aws_cloudwatch_log_group.cwlg0.name
              awslogs-region = "ap-northeast-1"
              awslogs-stream-prefix = "ecs"
          }
      }
    },
    {
      name      = "app"
      image     = var.appImg
      portMappings = [
        {
          containerPort = 8000
          protocol = "tcp"
          hostPort      = 8000
        }
      ]
      healthCheck = {
        retries = 3
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8000/ || exit 1"
        ]
        timeout = 5
        interval = 30
        startPeriod = null
      }
      essential = true
      logConfiguration = {
          logDriver = "awslogs"
          options = {
              awslogs-group = aws_cloudwatch_log_group.cwlg0.name
              awslogs-region = "ap-northeast-1"
              awslogs-stream-prefix = "ecs"
          }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "ecsSer0" {
  name                               = "ecsSer0"
  launch_type                        = "FARGATE"
  cluster                            = aws_ecs_cluster.ecsClu0.id
  task_definition                    = aws_ecs_task_definition.ecsTd0.arn
  platform_version                   = "LATEST"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 150
  enable_ecs_managed_tags            = true

  #deployment_circuit_breaker {
  #    enable  = true
  #    rollback = true 
  #}

  deployment_controller {
        type = "CODE_DEPLOY"
  }

  network_configuration {
   security_groups    = [aws_security_group.priSg0.id]
   subnets           = [aws_subnet.priSn0.id, aws_subnet.priSn1.id]
   assign_public_ip = false
 }

  load_balancer {
    target_group_arn = aws_lb_target_group.lbTg0.arn
    container_name   = "web"
    container_port   = 80
  }

  health_check_grace_period_seconds = 0
}

# ECS Appautoscaling Target
resource "aws_appautoscaling_target" "ecsAast0" {
  min_capacity       = 1
  max_capacity       = 3
  resource_id        = "service/ecsClu0/ecsSer0"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  depends_on = [aws_ecs_service.ecsSer0]
}

# ECS Appautoscaling Policy
resource "aws_appautoscaling_policy" "ecsAasp0" {
  name               = "ecsAasp0"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecsAast0.resource_id
  scalable_dimension = aws_appautoscaling_target.ecsAast0.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecsAast0.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 75
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

# Codedeploy App
resource "aws_codedeploy_app" "cdApp0" {
  compute_platform = "ECS"
  name             = "cdApp0"
}

resource "aws_codedeploy_deployment_group" "cdg0" {
    app_name               = aws_codedeploy_app.cdApp0.name
    deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
    #deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"
    deployment_group_name  = "cdg0"
    service_role_arn       = aws_iam_role.iamRole1.arn

    auto_rollback_configuration {
        enabled = true
        events  = ["DEPLOYMENT_FAILURE"]
    }

    blue_green_deployment_config {
        deployment_ready_option {
            action_on_timeout    = "STOP_DEPLOYMENT"
            wait_time_in_minutes = 1440
        }

        terminate_blue_instances_on_deployment_success {
            action                           = "TERMINATE"
            termination_wait_time_in_minutes = 10
        }
    }

    deployment_style {
        deployment_option = "WITH_TRAFFIC_CONTROL"
        deployment_type   = "BLUE_GREEN"
    }

    ecs_service {
        cluster_name = aws_ecs_cluster.ecsClu0.name
        service_name = aws_ecs_service.ecsSer0.name
    }

    load_balancer_info {

        target_group_pair_info {
            target_group {
                name = aws_lb_target_group.lbTg0.name
            }
            
            prod_traffic_route {
                listener_arns = [aws_lb_listener.lbLis0.arn]
            }

            target_group {
                name = aws_lb_target_group.lbTg1.name
            }

            test_traffic_route {
                listener_arns = [aws_lb_listener.lbLis2.arn]
            }
        }
    }
}*/

########## Uncomment and run above!! ##########



























########## Below is not important!! ##########
########## Care about above!!       ##########

/*resource "aws_security_group" "sg2" {
  name        = "blogEfsSg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port        = 2049
    to_port          = 2049
    protocol         = "tcp"
    security_groups  = [aws_security_group.sg1.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "blogEfsSg"
  }
}*/

/*
# EFS
resource "aws_efs_file_system" "efs1" {
  #creation_token = "staticDir"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "staticDir"
  }
}

resource "aws_efs_file_system" "efs2" {
  #creation_token = "mediaDir"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "mediaDir"
  }
}

# EFS Mount Target
resource "aws_efs_mount_target" "efs1Mt1" {
   file_system_id  = aws_efs_file_system.efs1.id
   #subnet_id = aws_subnet.priSn1.id
   subnet_id = aws_subnet.pubSn1.id
   security_groups = [aws_security_group.sg2.id]
}

resource "aws_efs_mount_target" "efs1Mt2" {
   file_system_id  = aws_efs_file_system.efs1.id
   #subnet_id = aws_subnet.priSn2.id      
   subnet_id = aws_subnet.pubSn2.id
   security_groups = [aws_security_group.sg2.id]
}

resource "aws_efs_mount_target" "efs2Mt1" {
   file_system_id  = aws_efs_file_system.efs2.id
   #subnet_id = aws_subnet.priSn1.id
   subnet_id = aws_subnet.pubSn1.id
   security_groups = [aws_security_group.sg2.id]
}

resource "aws_efs_mount_target" "efs2Mt2" {
   file_system_id  = aws_efs_file_system.efs2.id
   #subnet_id = aws_subnet.priSn2.id
   subnet_id = aws_subnet.pubSn2.id
   security_groups = [aws_security_group.sg2.id]
}
*/


/*
resource "aws_instance" "foo" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}
*/

/*
# IAM Policy
resource "aws_iam_policy" "policy_one" {
  name = "myAmazonECSTaskExecutionRolePolicy"

  policy = jsonencode(
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              #"Action": [
              #  "ecr:GetAuthorizationToken",
              #  "ecr:BatchCheckLayerAvailability",
              #  "ecr:GetDownloadUrlForLayer",
              #  "ecr:BatchGetImage",
              #  "logs:CreateLogStream",
              #  "logs:PutLogEvents"
              #],
              "Action": ["*"],
              "Resource": "*"
            }
          ]
        }
    )
}*/