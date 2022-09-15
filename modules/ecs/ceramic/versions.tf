terraform {
  required_version = ">= 1.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.22"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">=2.10.0"
    }
  }
}
