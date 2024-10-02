data aws_eks_cluster cluster {
  name  = var.cluster_name
}

data aws_eks_cluster_auth cluster {
  name  = var.cluster_name
}

resource "kubernetes_namespace" "namespace" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value

    labels = {
      managed_by        = "terraform"
      default_namespace = each.value == "putit" ? "true" : "false"
    }
  }
}
