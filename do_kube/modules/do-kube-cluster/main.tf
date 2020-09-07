resource "random_pet" "petname" {
  length    = 2
  separator = "-"
}

resource "digitalocean_kubernetes_cluster" "kube" {
  name    = "${var.env}-${random_pet.petname.id}"
  region  = var.region
  version = data.digitalocean_kubernetes_versions.versions.latest_version

  node_pool {
    name       = "${var.env}-${random_pet.petname.id}-node-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}

resource "digitalocean_project_resources" "resources" {
  project   = data.digitalocean_project.name.id
  resources = [
    "do:kubernetes:${digitalocean_kubernetes_cluster.kube.id}",
    ]
}

data "digitalocean_kubernetes_versions" "versions" {}

data "digitalocean_project" "name" {
  name = var.project_name
}

resource "random_password" "argopass" {
  length = 16
  special = true
  override_special = "_%@"
  depends_on = [
    digitalocean_kubernetes_cluster.kube,
  ]
}

resource "helm_release" "argocd_release" {
  name  = "argocd"
  namespace = "argocd"
  create_namespace = true
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"

  set {
    name = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(random_password.argopass.result)
  }

  set {
    name = "configs.secret.argocdServerAdminPasswordMtime"
    value = "date \"2030-01-01T23:59:59Z\" now"
  }

  depends_on = [
    random_password.argopass,
  ]
}

resource "kubectl_manifest" "cert-manager" {
    yaml_body = file("${path.module}/asset/cert-manager.yaml")

  depends_on = [
    random_password.argopass,
  ]
}

resource "helm_release" "nginx_ingress" {
  name      = "nginx"
  repository = "https://kubernetes-charts.storage.googleapis.com"
  chart     = "nginx-ingress"
  namespace = "kube-system"

  set {
    name = "controller.publishService.enabled"
    value = "true"
  }

  set {
    name = "controller.extraArgs.enable-ssl-passthrough"
    value = ""
  }

  depends_on = [
    kubectl_manifest.cert-manager
  ]
}

resource "kubernetes_ingress" "argocd_ingress" {
  metadata {
    name = "argocd-server-ingress"
    namespace = "argocd"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "kubernetes.io/ingress.class" = "nginx"
      "kubernetes.io/tls-acme" = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/ssl-passthrough"= "true"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
  }

  spec {
    rule {
      host = "argocd-${var.env}.${var.domain}"
      http {
        path {
          backend {
            service_name = "argocd-server"
            service_port = "https"
          }

          path = "/"
        }
      }
    }

    tls {
       hosts = [ "argocd-${var.env}.${var.domain}" ]
       secret_name = "argocd-secret"
    }
  }

  wait_for_load_balancer = true

  depends_on = [
    helm_release.nginx_ingress,
  ]
}


resource "digitalocean_record" "argocd" {
  domain = var.domain
  type   = "A"
  name   = "argocd-${var.env}"
  value  = kubernetes_ingress.argocd_ingress.load_balancer_ingress[0].ip
}


resource "kubectl_manifest" "dev-cert-manager" {
    yaml_body = file("${path.module}/asset/prod-certmgnt.yaml")

  depends_on = [
    kubernetes_ingress.argocd_ingress,
    kubectl_manifest.cert-manager,
  ]
}



