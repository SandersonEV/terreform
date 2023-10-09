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
    profile = "localstack"
    region = "us-east-1"
}

resource "aws_s3_bucket" "testeTerraform-bucket" {
    bucket = "teste-terraform-bucket"
}
