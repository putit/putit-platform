locals {
  # if any env would have more than one cluster, add it here
  cluster_map = {
    "${var.cluster_name}" = var.cluster_endpoint
  }
  cluster_base_name = replace(var.cluster_name, "-${var.environment}", "")
}

# Declarative cluster registration — replaces manual `argocd cluster add`
resource "kubernetes_secret" "argocd_cluster" {
  metadata {
    name      = var.cluster_name
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  data = {
    name   = var.cluster_name
    server = "https://kubernetes.default.svc"
    config = jsonencode({
      tlsClientConfig = {
        insecure = false
      }
    })
  }
}

data aws_eks_cluster cluster {
  name  = var.cluster_name
}

data aws_eks_cluster_auth cluster {
  name  = var.cluster_name
}

# set argocd projects - we can have multiple environments under single argocd.
resource "argocd_project" "project_per_env" {
  for_each = toset(var.environments_list)
  metadata {
    name      = "${var.tenant}-${each.key}"
    namespace = var.argocd_namespace
  }

  spec {
    description  = "Default project for all apps which runs onto the eks cluster."
    source_repos = ["*"]

    destination {
      server    = local.cluster_map["${local.cluster_base_name}-${each.key}"]
      namespace = "*"
    }

    # if we would have single env per argocd it could be static then
    destination {
      server    = local.cluster_map["${local.cluster_base_name}-${each.key}"]
      namespace = "*"
    }

    # perms for the role - dev
    role {
      name = "dev"
      policies = [
        "p, proj:${var.tenant}-${each.key}:dev, applications, override, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, applications, sync, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, clusters, get, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, clusters, update, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, repositories, create, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, repositories, delete, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, repositories, update, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, logs, get, ${var.tenant}-${each.key}/*, allow",
        "p, proj:${var.tenant}-${each.key}:dev, exec, create, ${var.tenant}-${each.key}/*, allow",
      ]
    }

    cluster_resource_blacklist {
      group = "*"
      kind  = "*"
    }
    cluster_resource_whitelist {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRoleBinding"
    }
    cluster_resource_whitelist {
      group = "rbac.authorization.k8s.io"
      kind  = "ClusterRole"
    }
    namespace_resource_whitelist {
      group = "networking.k8s.io"
      kind  = "Ingress"
    }
    namespace_resource_whitelist {
      group = "*"
      kind  = "*"
    }
    orphaned_resources {
      warn = true
    }
  }
}

# Git Generator - Directories
resource "argocd_application_set" "git_directories" {
  for_each = toset(var.environments_list)
  metadata {
    name      = "${var.tenant}-${each.key}-git-dir-generator"
    namespace = var.argocd_namespace
  }

  spec {
    generator {
      matrix {
        generator {
          git {
            repo_url = var.app_repo_url
            revision = var.target_revision

            directory {
              path = "apps/*"
            }
          }
        }

        generator {
          list {
            elements = [
              {
                cluster = "${local.cluster_base_name}-${each.key}"
                url     = local.cluster_map["${local.cluster_base_name}-${each.key}"]
                namespace = var.default_namespace_target
              }
            ]
          }
        }
      }
    }


    template {
      metadata {
        name = "{{cluster}}-{{path.basename}}"
      }

      spec {
        project = "${var.tenant}-${each.key}"
        source {
          repo_url        = var.app_repo_url
          target_revision = var.target_revision
          path            = "{{path}}/charts"
          helm {
            value_files = ["values-${each.key}.yaml"]
            release_name = "{{path.basename}}"
            parameter {
              name = "envs.EXAMPLE_VAR"
              value = "example"
            }
          }
        }

        destination {
          server    = "{{url}}"
          namespace = var.default_namespace_target
        }

        ignore_difference {
          group         = "apps"
          kind          = "Deployment"
          json_pointers = ["/spec/replicas"]
        }
      }
    }
  }
}
