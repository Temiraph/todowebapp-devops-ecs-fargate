variable "db_name" {
  description = "Database name for the Todo app"
  type        = string
  default     = "todoappdb"
}

variable "db_username" {
  description = "username for RDS"
  type        = string
}

variable "db_password" {
  description = "password for RDS"
  type        = string
  sensitive   = true
}

variable "app_image" {
  description = "Container image for the Todo app"
  type        = string
}


