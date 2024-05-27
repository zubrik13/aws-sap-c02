# aws
variable "profile" {
  description = "AWS profile to use"
  type        = string
  default     = "orbit"
}

variable "region" {
  description = "AWS region to deploy resource in"
  type        = string
  default     = "eu-central-1"
}

# vpc
variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.0.0.0/24"
}

# org
