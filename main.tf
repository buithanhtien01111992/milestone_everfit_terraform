terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.15"
        }
    }

    required_version = ">= 1.2.5"
}

provider "aws" {
    region  = "ap-southeast-1"
}

variable "db_username" {
  description = "Username for the RDS database"
}

variable "db_password" {
  description = "Password for the RDS database"
}

module "ec2_with_rds" {
    source            = "./module"
    ec2_ami_id        = "ami-047126e50991d067b"
    ec2_instance_type = "t2.small"

    db_username       = var.db_username
    db_password       = var.db_password
}

output "ec2_ssh_cmd" {
    value = module.ec2_with_rds.ssh_ec2_instance
}

output "rds_endpoint" {
    value = module.ec2_with_rds.rds_instance
}