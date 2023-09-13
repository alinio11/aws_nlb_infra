terraform {
  required_version = ">=1.5.0"
  required_providers {
    //Specifies the cloud provider type to use.
    aws = {
      //Specifies the source of commands that Terraform will reference.
      source = "hashicorp/aws"
      //Specifies the version of terraform.
      version = "~>4.0"
      #version = "~> 5.0"
      //Set of values to be derived from az login.
      #subscription_id = var.subscription_id
      #client_id       = var.client_id
      #client_secret   = var.client_secret
      #tenant_id       = var.tenant_id
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.1"
    }
  }
}

provider "aws" {
  region                  = var.region
  #shared_credentials_file = "~/.aws/credentials"
  profile                 = "terraform_admin"
}