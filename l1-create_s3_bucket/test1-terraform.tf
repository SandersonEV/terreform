# This is my first try usind terraform.
# My plan is to use localstack insted of the aws cloud to avoid of pay for unused services of the cloud.

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "3.27"
    }
  }
  required_version = ">= 0.13.4"
}
provider "aws" {
    profile = "localstack" # This is the fake profile created to interact with localstak. AWS-CLI always ask to a account on aws even if you are using localstack container to simulate aws
    region = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    s3_force_path_style = true
    skip_requesting_account_id = true

    endpoints {
      s3 = "http://localhost:4566"
    }
}


resource "aws_s3_bucket" "testeTerraform-bucket" {
    bucket = "teste-terraform-bucket"
    
}
