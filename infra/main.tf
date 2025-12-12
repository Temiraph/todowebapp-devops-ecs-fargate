terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "to-do-list-785674475y" 
    key            = "infra/terraform.tfstate"
    region         = "eu-west-2"      
    dynamodb_table = "todo-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-2" 
  profile = "todo-devops" 
}

  resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "todo-devops-vpc"
    Project = "todo-devops-todoapp"
  }
}

# Public subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "todo-public-a"
    Project = "todo-devops-todoapp"
    Tier    = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name    = "todo-public-b"
    Project = "todo-devops-todoapp"
    Tier    = "public"
  }
}

# Private subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "todo-private-a"
    Project = "todo-devops-todoapp"
    Tier    = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "todo-private-b"
    Project = "todo-devops-todoapp"
    Tier    = "private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "todo-igw"
    Project = "todo-devops-todoapp"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "todo-public-rt"
    Project = "todo-devops-todoapp"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name    = "todo-nat-eip"
    Project = "todo-devops-todoapp"
  }
}

# NAT Gateway in public subnet A
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name    = "todo-nat-gw"
    Project = "todo-devops-todoapp"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Private route table (uses NAT for internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name    = "todo-private-rt"
    Project = "todo-devops-todoapp"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# Security Group for ALB - public HTTP
resource "aws_security_group" "alb_sg" {
  name        = "todo-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "todo-alb-sg"
    Project = "todo-devops-todoapp"
  }
}

# Security Group for app/ECS tasks - only from ALB
resource "aws_security_group" "app_sg" {
  name        = "todo-app-sg"
  description = "App/ECS tasks security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "HTTP from ALB"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "todo-app-sg"
    Project = "todo-devops-todoapp"
  }
}

// Security Group for RDS - only from app_sg
resource "aws_security_group" "db_sg" {
  name        = "todo-db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "MySQL from app"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "todo-db-sg"
    Project = "todo-devops-todoapp"
  }
}

// DB subnet group (use private subnets)
resource "aws_db_subnet_group" "todo_db_subnet_group" {
  name       = "todo-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name    = "todo-db-subnet-group"
    Project = "todo-devops-todoapp"
  }
}

// RDS MySQL instance
resource "aws_db_instance" "todo_db" {
  identifier        = "todo-db-instance"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"   
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  multi_az               = false      
  publicly_accessible    = false
  storage_encrypted      = true
  skip_final_snapshot    = true      
  deletion_protection    = false

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.todo_db_subnet_group.name

  backup_retention_period = 7
  auto_minor_version_upgrade = true

  tags = {
    Name    = "todo-mysql-db"
    Project = "todo-devops-todoapp"
  }
}
// ECR Repository for app container
resource "aws_ecr_repository" "todo_ecr" {
  name                 = "todo-app-repo"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "todo-app-ecr"
    Project = "todo-devops-todoapp"
  }
}
// SSM parameters for database configuration

resource "aws_ssm_parameter" "db_host" {
  name  = "/todo-app/db/host"
  type  = "String"
  value = aws_db_instance.todo_db.address

  tags = {
    Project = "todo-devops-todoapp"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/todo-app/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Project = "todo-devops-todoapp"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/todo-app/db/username"
  type  = "SecureString"
  value = var.db_username

  tags = {
    Project = "todo-devops-todoapp"
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/todo-app/db/password"
  type  = "SecureString"
  value = var.db_password

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# IAM role for ECS task execution (ECR, CloudWatch, SSM)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "todo-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# Attach AWS managed policy for ECS tasks (ECR + logs)
resource "aws_iam_role_policy_attachment" "ecs_task_exec_base" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra inline policy for reading SSM parameters
resource "aws_iam_role_policy" "ecs_task_exec_ssm" {
  name = "todo-ecs-task-exec-ssm-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = [
          aws_ssm_parameter.db_host.arn,
          aws_ssm_parameter.db_name.arn,
          aws_ssm_parameter.db_username.arn,
          aws_ssm_parameter.db_password.arn
        ]
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "todo_cluster" {
  name = "todo-todoapp-cluster"

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# CloudWatch log group for app logs
resource "aws_cloudwatch_log_group" "todo_app" {
  name              = "/ecs/todo-app"
  retention_in_days = 7

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# ECS Task Definition (Fargate)
resource "aws_ecs_task_definition" "todo_task" {
  family                   = "todo-app-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "todo-app"
      image     = var.app_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      secrets = [
        {
          name      = "DB_HOST"
          valueFrom = aws_ssm_parameter.db_host.arn
        },
        {
          name      = "DB_NAME"
          valueFrom = aws_ssm_parameter.db_name.arn
        },
        {
          name      = "DB_USER"
          valueFrom = aws_ssm_parameter.db_username.arn
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.todo_app.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "todo-app"
        }
      }
    }
  ])

  tags = {
    Project = "todo-devops-todoapp"
  }
}

// Application Load Balancer
resource "aws_lb" "todo_alb" {
  name               = "todo-app-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]
  subnets         = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# Target Group for ECS tasks (IP mode for Fargate)
resource "aws_lb_target_group" "todo_tg" {
  name        = "todo-app-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Project = "todo-devops-todoapp"
  }
}

# Listener for ALB (HTTP 80 -> target group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.todo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.todo_tg.arn
  }
}

# ECS Service - runs tasks on Fargate and registers with ALB
resource "aws_ecs_service" "todo_service" {
  name            = "todo-app-service"
  cluster         = aws_ecs_cluster.todo_cluster.id
  task_definition = aws_ecs_task_definition.todo_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.todo_tg.arn
    container_name   = "todo-app"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.http
  ]

  tags = {
    Project = "todo-devops-todoapp"
  }
}

resource "aws_sns_topic" "alarms" {
  name = "todo-app-alarms"

  tags = {
    Project = "todo-devops-todoapp"
  }
}
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "todo-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    LoadBalancer = aws_lb.todo_alb.arn_suffix
  }

  alarm_description = "Alert when ALB returns 5XX errors"
  alarm_actions     = [aws_sns_topic.alarms.arn]

  tags = {
    Project = "todo-devops-todoapp"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "todo-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.todo_cluster.name
    ServiceName = aws_ecs_service.todo_service.name
  }

  alarm_description = "Alert when ECS service CPU usage is consistently high"
  alarm_actions     = [aws_sns_topic.alarms.arn]

  tags = {
    Project = "todo-devops-todoapp"
  }
}
