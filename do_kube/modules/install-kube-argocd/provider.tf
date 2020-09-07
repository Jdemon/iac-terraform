terraform {
  required_providers {
    random = {
        source = "hashicorp/random"
        version = "~> 2.3.0"
    }
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~> 1.13.1"
    }
    helm = {
        source = "hashicorp/helm"
        version = "~> 1.3"
    }
    kubectl = {
        source = "hashicorp/kubectl"
        version = "~> 1.2.6"
    }
  }
}