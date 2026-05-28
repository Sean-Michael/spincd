variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "spincd"
}

variable "scan_prefix" {
  description = "Key prefix within the bucket that holds publicly-readable scan images"
  type        = string
  default     = "scans"
}
