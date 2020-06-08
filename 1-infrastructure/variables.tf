variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "VPC cidr block"
}

variable "public_subnet_1_cidr" {
  description = " Public subnet 1 cidr"

}

variable "public_subnet_2_cidr" {
  description = " Public subnet 2 cidr"

}

variable "public_subnet_3_cidr" {
  description = " Public subnet 3 cidr"

}

variable "private_subnet_1_cidr" {
  description = " private subnet 1 cidr"

}


variable "private_subnet_2_cidr" {
  description = " private subnet 2 cidr"

}

variable "private_subnet_3_cidr" {
  description = " private subnet 3 cidr"

}