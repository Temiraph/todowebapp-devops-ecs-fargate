# Todo Application — AWS ECS Fargate DevOps Project

## Overview
This project demonstrates deploying a production-style Node.js Todo application on AWS using modern DevOps and cloud best practices.

The application runs on **Amazon ECS with Fargate**, is fronted by an **Application Load Balancer**, and uses **Amazon RDS (MySQL)** for persistence.  
All infrastructure is provisioned using **Terraform**.

## Architecture
- ECS Fargate (containerized Node.js app)
- Application Load Balancer (public entry point)
- Amazon RDS MySQL (private subnets)
- Amazon ECR (container registry)
- AWS VPC with public and private subnets
- NAT Gateway for private subnet egress
- IAM roles with least-privilege access
- AWS SSM Parameter Store for secrets

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
