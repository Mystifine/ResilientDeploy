resource "aws_ecs_cluster" "main" {
  name = "resilient-deploy-cluster"

  tags = {
    Name = "resilient-deploy-cluster"
  }
}

resource "aws_iam_role" "ecs_execution" {
  name = "resilient-deploy-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "resilient-deploy-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/resilient-deploy"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "app" {
  family = "resilient-deploy"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name = "resilient-deploy"
      image = "474665692949.dkr.ecr.us-east-1.amazonaws.com/resilient-deploy:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 8080,
          protocol = "tcp"
        }
      ],

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = aws_cloudwatch_log_group.app.name,
          "awslogs-region" = "us-east-1",
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "resilient-deploy-task"
  }
}

resource "aws_ecs_service" "app" {
  name = "resilient-deploy-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 2
  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name = "resilient-deploy"
    container_port = 8080
  }

  depends_on = [aws_lb_listener.http]
}
