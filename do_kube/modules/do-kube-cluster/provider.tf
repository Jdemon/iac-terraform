terraform {
  required_providers {
    digitalocean = {
        source = "digitalocean/digitalocean"
        version = "~> 1.22"
    }
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
        source = "kubectl"
        version = "~> 1.6.2"
    }

    tls = {
        source = "hashicorp/tls"
        version = "~> 2.2"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  load_config_file = false
  host  = digitalocean_kubernetes_cluster.kube.endpoint
  token = digitalocean_kubernetes_cluster.kube.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.kube.kube_config[0].cluster_ca_certificate
  )
}

provider "kubectl" { 
  load_config_file = false
  host  = digitalocean_kubernetes_cluster.kube.endpoint
  token = digitalocean_kubernetes_cluster.kube.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.kube.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host  = digitalocean_kubernetes_cluster.kube.endpoint
    token = digitalocean_kubernetes_cluster.kube.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.kube.kube_config[0].cluster_ca_certificate
    )
  }
}

