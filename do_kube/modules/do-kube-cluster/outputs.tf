output "k8s_version" {
    value = digitalocean_kubernetes_cluster.kube.version
}

output "k8s_region" {
    value = digitalocean_kubernetes_cluster.kube.region
}

output "node_count" {
    value = digitalocean_kubernetes_cluster.kube.node_pool[0].actual_node_count
}

output "master_node_ip" {
    value = digitalocean_kubernetes_cluster.kube.ipv4_address
}
 

output "argocd_initial_password" {
  value = random_password.argopass.result
  sensitive = true  
}