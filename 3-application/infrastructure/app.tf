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
#passing in the port config for the actual spring boot application
#this appows application to fo out to the internet freely without any limitations of ports or protocols
# 
    ingress {
        from_port = 8080
        protocol = "TCP"
        to_port = 8080
        cidr_blocks = [data.terraform_remote_state.platform.vpc_cidr_blocks]
    }

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0 
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "${var.ecs_service_name}-SG"

    }
}

#creating alb target group for the ecs-fargate tasks where we can use it for the application load balalncer. 


resource "aws_alb_target_group" "ecs_app_target_group" {
    name = "${var.ecs_service_name}-TG"
    port = "${var.docker_container_port}"
    protocol = "HTTP"
    vpc_id = "${data.terraform_remote_state.platform.vpc_id}"
    target_type = "ip"
  
    #providing a health check mechanism for the application so that EC@ target groups can 
    #understand that the application is healthy and then fargate can reconize 
    health_check{
        path = "/actuator/health"
        protocol = "HTTP"
        matcher = "200"
        #intervals for the check 
        interval = 60
        timeout = 30
        #after 3 re-tries of unhealthy application health checks it is going to go down and deregister from this target group
        unhealthy_threshold = "3"
        healthy_threshold = "3"
    }
    
    tags {
        Name = "${var.ecs_service_name}-TG"
    }

}

#creating ecs service 