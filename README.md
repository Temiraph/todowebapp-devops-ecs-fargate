# Todo Application — AWS ECS Fargate DevOps Project

## Overview
This project demonstrates deploying a production-style Node.js Todo application on AWS using modern DevOps and cloud best practices.

The application runs on **Amazon ECS with Fargate**, is fronted by an **Application Load Balancer**, and uses **Amazon RDS (MySQL)** for persistence.  
All infrastructure is provisioned using **Terraform**.

## Architecture
- Internet Users access the application via HTTP.
- Application Load Balancer (ALB) in public subnets receives traffic and forwards requests to the application.
- ECS Fargate Service runs multiple containerized tasks of the Node.js Todo app in private subnets.
- Amazon RDS MySQL stores application data and is only accessible from ECS tasks.
- Amazon ECR stores Docker images pulled by ECS during deployments.
- AWS SSM Parameter Store (SecureString) supplies database credentials securely at runtime.
- CloudWatch Logs & Alarms provide logging and alerting (ALB 5XX errors, ECS CPU utilization).
- GitHub Actions CI/CD builds Docker images, pushes to ECR, and triggers ECS rolling deployments.

## Networking & Security

- Custom VPC across multiple Availability Zones
    Public subnets: Application Load Balancer
    Private subnets: ECS Fargate tasks and RDS
- NAT Gateway allows private resources outbound access
- Security Groups (least-privilege):
    ALB SG: allows inbound HTTP (80) from the internet
    App SG: allows inbound app traffic only from the ALB
    DB SG: allows MySQL access only from the app security group
- Secrets Management:
    Database credentials stored in SSM SecureString
    No secrets committed to source control

## DevOps & Cloud Tools Used
- Terraform (Infrastructure as Code)
- Docker (containerization)
- Amazon ECS Fargate
- Amazon ECR
- Application Load Balancer
- Amazon RDS (MySQL)
- AWS SSM Parameter Store
- CloudWatch Logs
- Git & GitHub

## CI/CD Pipeline
- Triggered on push to the main branch
- Steps:
  Build Docker image
  Push image to Amazon ECR
  Trigger ECS rolling redeployment (force-new-deployment)
  Ensures consistent, automated deployments with zero downtime.

## Monitoring & Reliability
- CloudWatch Alarms configured for:
    ALB 5XX error rates
    ECS service CPU utilization
- SNS notifications for operational alerts
- ALB health checks ensure only healthy ECS tasks receive traffic.

## Key DevOps Practices
- Infrastructure fully defined as code (Terraform)
- Secrets not hard-coded (SSM SecureString)
- Containers built once and deployed consistently
- Private networking for application and database
- Load-balanced, highly available service
- Troubleshooting via ECS events and CloudWatch logs

## Deployment
1. Build and push Docker image to ECR
2. Provision infrastructure with Terraform
3. ECS service pulls image and runs tasks on Fargate
4. ALB routes traffic to healthy tasks

## Outcome
The application is accessible via the Application Load Balancer DNS endpoint and scales independently of the underlying infrastructure.

## Lessons Learned
- Debugging ECS task failures using ECS events and stopped task reasons
- Resolving ECR image pull issues caused by missing tags and authentication
- Designing secure VPC networking with public and private subnets
