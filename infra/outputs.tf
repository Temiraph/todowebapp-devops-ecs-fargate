// Application access
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.todo_alb.dns_name
}

// Networking
output "vpc_id" {
  description = "VPC ID for the Todo application"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnets used by the ALB"
  value       = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "private_subnet_ids" {
  description = "Private subnets used by ECS and RDS"
  value       = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

// Compute
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.todo_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.todo_service.name
}

// Load balancing
output "alb_target_group_arn" {
  description = "Target group ARN used by ECS service"
  value       = aws_lb_target_group.todo_tg.arn
}

//Container registry
output "ecr_repository_url" {
  description = "ECR repository URL for the application image"
  value       = aws_ecr_repository.todo_ecr.repository_url
}

//Database (safe info only)
output "rds_endpoint" {
  description = "RDS endpoint (hostname only)"
  value       = aws_db_instance.todo_db.address
}
