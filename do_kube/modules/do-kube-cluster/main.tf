resource "random_pet" "petname" {
  length    = 2
  separator = "-"
}

resource "digitalocean_kubernetes_cluster" "kube" {
  name    = "kube-${var.env}"
  region  = var.region
  version = data.digitalocean_kubernetes_versions.versions.latest_version

  node_pool {
    name       = "${var.env}-${random_pet.petname.id}-node-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}

data "digitalocean_kubernetes_versions" "versions" {}

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

  set {
    name  = "server.extraArgs[0]"
    type = "string"
    value = "--insecure"
  }

  depends_on = [
    random_password.argopass,
  ]
}

resource "kubernetes_ingress" "argocd_ingress" {
  metadata {
    name = "argocd-server-ingress"
    namespace = "argocd"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "kubernetes.io/tls-acme" = "true"
      "kubernetes.io/ingress.class" = "kong"
      "kubernetes.io/ingress.allow-http" = "false"
      "konghq.com/https-redirect-status-code" = "307"
      "configuration.konghq.com/protocols" = "https"
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
    kubectl_manifest.dev-cert-manager,
  ]
}


resource "digitalocean_record" "argocd" {
  domain = var.domain
  type   = "A"
  name   = "argocd-${var.env}"
  value  = kubernetes_ingress.argocd_ingress.load_balancer_ingress[0].ip
}

