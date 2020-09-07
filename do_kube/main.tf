module "do-kube-cluster" {
    source = "./modules/do-kube-cluster"
    region = "sgp1"
    do_token = var.do_token
    project_name = var.project_name
    env = var.env
    node_size = var.node_size
    node_count = var.node_count
    domain = var.domain
}