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

