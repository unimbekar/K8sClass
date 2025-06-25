terraform {
  backend "s3" {
    region = "us-east-1"
    bucket = "k8sclass-tf-state-0625"
    key    = "eks/terraform.tfstate"
    profile = "default"
  }
}
