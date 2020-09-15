resource "digitalocean_database_cluster" "kube_postgres" {
  name       = "agentmate-dev-postgres"
  engine     = "pg"
  version    = "12"
  size       = "db-s-1vcpu-1gb"
  region     = "sgp1"
  node_count = 1
}

resource "digitalocean_database_firewall" "kube_postgres_fw" {
  cluster_id = digitalocean_database_cluster.kube_postgres.id

  rule {
    type  = "k8s"
    value = digitalocean_kubernetes_cluster.kube.id
  }
}


resource "digitalocean_database_db" "kong_db" {
  cluster_id = digitalocean_database_cluster.kube_postgres.id
  name       = "kong"
}

resource "digitalocean_database_user" "kong_user" {
  cluster_id = digitalocean_database_cluster.kube_postgres.id
  name       = "kong"
}

resource "digitalocean_database_connection_pool" "kong_connection" {
  cluster_id = digitalocean_database_cluster.kube_postgres.id
  name       = "kong_pool"
  mode       = "transaction"
  size       = 4
  db_name    = digitalocean_database_db.kong_db.name
  user       = digitalocean_database_user.kong_user.name
}
