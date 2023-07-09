resource "helm_release" "prometheus" {
  name = "prometheus"

  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    "${file("./helm-values-files/prometheus-values.yaml")}"
  ]
}

resource "helm_release" "istio_base" {
  name = "istio-base-release"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true

  set {
    name  = "global.istioNamespace"
    value = "istio-system"
  }
}

resource "helm_release" "istiod" {
  name = "istiod"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  namespace        = "istio-system"

  set {
    name  = "telemetry.enabled"
    value = "true"
  }

  set {
    name  = "global.istioNamespace"
    value = "istio-system"
  }

  set {
    name  = "meshConfig.ingressService"
    value = "istio-gateway"
  }

  set {
    name  = "meshConfig.ingressSelector"
    value = "gateway"
  }

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  namespace        = "istio-ingress"
  create_namespace = true

  set {
    name  = "service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
  
  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}

resource "helm_release" "cert-manager" {
  name = "cert-manager"

  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "extraArgs"
    value = "{--dns01-recursive-nameservers=8.8.8.8:53\\,1.1.1.1:53}"
  }

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.servicemonitor.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.servicemonitor.labels.release"
    value = "prometheus"
  }

}

resource "helm_release" "duckdns-webhook" {
  name = "cert-manager-webhook-duckdns"

  repository       = "https://ebrianne.github.io/helm-charts"
  chart            = "cert-manager-webhook-duckdns"
  namespace        = "cert-manager"

  values = [
    "${file("./helm-values-files/duckdns-webhook.yaml")}"
  ]

  depends_on = [helm_release.cert-manager]
}

resource "helm_release" "autoscaler" {
  name = "autoscaler-release"

  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  namespace        = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = "${var.prefix}-cluster"
  }

  set {
    name  = "awsRegion"
    value = "${data.aws_region.current.name}"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = "${aws_iam_role.eks_cluster_autoscaler.arn}"
  }

  set {
    name  = "image.tag"
    value = "v1.24.2"
  }

}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

}