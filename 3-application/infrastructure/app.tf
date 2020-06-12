provider "aws" {
    region = var.region
}

terraform {
    backend "s3"{}
}

data "terraform_remote_state" "platform"{
    backend = "s3"

    config = {
        key = var.remote_state_key
        bucket = var.remote_state_bucket
        region = var.region 
    }
}

data "template_file" "ecs_task_defintion_template" {
    template = "${file("task_defintion.json")}"

    vars = {
        task_defintion_name = var.ecs_service_name
        ecs_service_name = var.ecs_service_name
        docker_image_url = var.docker_image_url
        memory = var.memory 
        docker_container_port = var.docker_container_port
        spring_profile = var.spring_profile 
        region = var.region
    }
}

resource "aws_ecs_task_definition" "springbootapp-task-defintion" {
    container_defintions = data.template_file.ecs_task_defintion_template.rendered
    family = var.ecs_service_name
    cpu = 512
    memory = var.memory
    requires_compatibilities = ["FARGATE"]
    networking_mode = "awsvpc"
    execution_role_arn = ""
    task_role_arn = ""
}

#use json inline document
resource "aws_iam_role" "fargate_iam_role" {
    name = "${var.ecs_service_name}-IAM-Role"
    assume_role_policy = << EOF
{
    "version":"2012-10-17"
    "Statement" : [{
        "Effect":"Allow, 
        "Principal": {
            "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
        }, 
        "Action": "sts:AssumeRole"
    }]
}
    EOF
}
resource "aws_iam_role_policy" "fargate_iam_role_policy" {
    name = "${var.ecs_service_name}-IAM-Role_policy"
    role = aws_iam_role.fargate_iam_role.id
    policy = <<EOF
    {
        "Version" : "2012-10-17", 
        "Statement": [{
            "Effect": "Allow",
            "Action" : [
                "ecs:*",
                "ecr:*", 
                "logs:*",
                "cloudwatch:*", 
                "elasticloadbalancing:*"
            ],
            "Resource" : "*"
        }]
    }
    EOF
}

#security group for the application on fargate 

resource "aws_security_group" "app_security_group" {
    name = "${var.ecs_service_name}-SG"
    description = "Security group for springbootapp to communicate in and out"
    vpc_id = data.terraform_remote_state.platform.vpc_id
}