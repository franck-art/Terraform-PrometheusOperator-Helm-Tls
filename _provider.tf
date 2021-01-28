
provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}
provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}