terraform {
  required_version = "~> 0.12.31"

  backend "s3" {
    bucket = "brad-terraform-state-us-east-1"
    key    = "istio-blue-green-post-istio.tfstate"
    region = "us-east-1"
    profile = "supportfog"
  }
}

data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "brad-terraform-state-us-east-1"
    key    = "istio-blue-green.tfstate"
    region = "us-east-1"
    profile = "supportfog"
  }
}

data "aws_caller_identity" "current" {}

data "kubernetes_service" "ingress_lb" {
  provider = kubernetes.eks

  metadata {
    name      = "istio-ingressgateway"
    namespace = "istio-system"
  }
}

data "aws_lb" "ingress" {
  name = regex("^[^-]+", data.kubernetes_service.ingress_lb.load_balancer_ingress.0.hostname)
}

provider "aws" {
  region  = "us-west-2"
  profile = "supportfog"
  version = "~> 2.45"
}

# Mandatory:

variable "tags" {
  type = map(string)
  default = {
    CostCenter = "brad@foghornconsulting.com"
  }
}

data "aws_eks_cluster" "eks" {
  name = data.terraform_remote_state.main.outputs.eks_cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = data.terraform_remote_state.main.outputs.eks_cluster_id
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.eks.token
  load_config_file       = false
  version                = "1.11.1"
}

resource "aws_route53_record" "bookinfo" {
  name    = "bookinfo"
  type    = "A"
  zone_id = data.terraform_remote_state.main.outputs.zone_id
  alias {
    evaluate_target_health = false
    name                   = data.aws_lb.ingress.dns_name
    zone_id                = data.aws_lb.ingress.zone_id
  }
}

resource "aws_route53_record" "bookinfo-test" {
  name    = "bookinfo-test"
  type    = "A"
  zone_id = data.terraform_remote_state.main.outputs.zone_id
  alias {
    evaluate_target_health = false
    name                   = data.aws_lb.ingress.dns_name
    zone_id                = data.aws_lb.ingress.zone_id
  }
}
