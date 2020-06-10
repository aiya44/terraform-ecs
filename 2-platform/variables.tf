variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "remote_state_bucket" {}
variable "remote_state_key" {}
variable "ecs_cluster_name" {}

variable "internet_cidr_block" {

}

variable "ecs_domain_name" {
  
}

