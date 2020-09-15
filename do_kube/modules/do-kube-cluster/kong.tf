resource "helm_release" "kong_release" {
  name  = "kong"
  namespace = "kong"
  create_namespace = true
  repository = "https://charts.konghq.com"
  chart = "kong"

  set {
    name = "ingressController.installCRDs"
    value = false
  }

  set {
    name = "image.repository"
    value = "jaykmutt/kong"
  }

  set {
    name = "image.tag"
    value = "2.1"
  }

  set {
    name = "env.database"
    value = "postgres"
  }

  set {
    name = "env.pg_host"
    value = digitalocean_database_connection_pool.kong_connection.private_host
  }

  set {
    name = "env.pg_port"
    value = digitalocean_database_connection_pool.kong_connection.port
  }

  set {
    name = "env.pg_user"
    value = digitalocean_database_connection_pool.kong_connection.user
  }

  set {
    name = "env.pg_password"
    value = digitalocean_database_connection_pool.kong_connection.password
  }

  set {
    name = "env.pg_database"
    value = digitalocean_database_connection_pool.kong_connection.name
  }

  set {
    name = "env.pg_ssl"
    value = "on"
  }

  set {
    name = "env.plugins"
    type = "string"
    value = "bundled\\,oidc"
  }

  set {
    name = "env.trusted_ips"
    type = "string"
    value= "0.0.0.0/0\\,::/0"
  }

  depends_on = [
    helm_release.linkerd,
    kubectl_manifest.cert-manager
  ]
}

resource "kubectl_manifest" "dev-cert-manager" {
    yaml_body = file("${path.module}/asset/prod-certmgnt.yaml")

  depends_on = [
    helm_release.kong_release,
  ]
}

resource "kubectl_manifest" "cert-manager" {
    yaml_body = file("${path.module}/asset/cert-manager.yaml")
    depends_on = [
      helm_release.argocd_release,
    ]
}

resource "digitalocean_record" "kong_admin" {
  domain = var.domain
  type   = "A"
  name   = "kong-${var.env}"
  value  = kubernetes_ingress.argocd_ingress.load_balancer_ingress[0].ip
}
