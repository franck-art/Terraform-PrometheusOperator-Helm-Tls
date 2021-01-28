#~-~-~~~~~~~~~~~~~#
# MONITORING HELM #
#~-~-~~~~~~~~~~~~~#

resource "kubernetes_namespace" "monitoring" {
  metadata {
    annotations = {
      name = "monitoring"
    }
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    annotations = {
      name = "cert-manager"
    }
    name = "cert-manager"
  }
}

resource "random_password" "password" {
  length = 32
  special = true
}

resource "kubernetes_secret" "prometheus-password" {
  metadata {
    name = "prom-password"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    password = base64encode(random_password.password.result)
  }
}

resource "helm_release" "prometheus-stack" {
  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  timeout    = 700
    values = [
    file("./charts/values.yaml")
  ]
  set {
    name  = "grafana.adminPassword"
    value = kubernetes_secret.prometheus-password.data["password"]
  }
 depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  depends_on = [kubernetes_namespace.monitoring,]
}

resource "helm_release" "certmanager-tls" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [kubernetes_namespace.cert-manager]
}