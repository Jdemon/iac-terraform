output "argocd_password" {
  value = module.do-kube-cluster.argocd_initial_password
  sensitive = true 
}