provider "aws" {
  alias   = "staging"
  profile = "staging"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "production"
  profile = "production"
  region  = "ap-northeast-1"
}

provider "aws" {
  alias   = "global"
  profile = "staging"
  region  = "us-east-1"
}


terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.76.0"
    }
  }
  backend "s3" {
    region               = "ap-northeast-1"
    profile              = "staging"
    bucket               = "sample-tfstate"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "infra"
  }

}

module "staging" {
  source = "./staging"
  providers = {
    aws = aws.staging
  }
}

module "production" {
  source = "./production"
  providers = {
    aws = aws.production
  }
}
