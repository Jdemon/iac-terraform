variable "do_token" {
    description = "DigitalOcean Token"
}

variable "project_name" {
    description = "DO Project Name"
}

variable "env" {
    description = "Environtment env"
}

variable "node_size" {
    //s-2vcpu-4gb
    description = "Droplet instance Size"
}

variable "node_count" {
    description = "Droplet instance Size"
}

variable "region" {
    default = "sgp1"
    description = "Region"
}

variable "domain" {
    description = "Domain Name"
}