variable "aws_region" {
  type        = string
  default     = "ap-southeast-1"
}

variable "ami_id" {
  type        = string
  default     = "ami-078c1149d8ad719a7"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
}

variable "dockerhub_username" {
  type        = string
}

variable "app_port" {
  type        = number
  default     = 3000
}
