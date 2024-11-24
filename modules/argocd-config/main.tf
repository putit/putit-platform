
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

locals {
  argocd_auth_token = "EaEpD6lq5kfMwtg9" # Wprowadź tutaj swój token
}


# Definicja projektu ArgoCD
resource "argocd_project" "project" {
  metadata {
    name      = "${var.tenant}-${var.environment}"
    namespace = "argocd"
  }

  spec {
    description  = "Project for all apps running on the EKS cluster."
    source_repos = ["*"]

    destination {
      server    = data.aws_eks_cluster.cluster.endpoint
      namespace = "*"
    }

    role {
      name = "dev"
      policies = [
        "p, proj:${var.tenant}-${var.environment}:dev, applications, override, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, applications, sync, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, clusters, get, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, clusters, update, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, repositories, create, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, repositories, delete, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, repositories, update, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, logs, get, ${var.tenant}-${var.environment}/*, allow",
        "p, proj:${var.tenant}-${var.environment}:dev, exec, create, ${var.tenant}-${var.environment}/*, allow",
      ]
    }

    cluster_resource_blacklist {
      group = "*"
      kind  = "*"
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

# Definicja ArgoCD Application Set
resource "argocd_application_set" "git_directories" {
  metadata {
    name      = "${var.tenant}-${var.environment}-git-dir-generator"
    namespace = "argocd"
  }

  spec {
    generator {
      matrix {
        generator {
          git {
            repo_url = var.app_repo_url
            revision = var.target_revision

            directory {
              path = "chart/*"
            }
          }
        }

        generator {
          list {
            elements = [
              {
                cluster   = data.aws_eks_cluster.cluster.name
                url       = data.aws_eks_cluster.cluster.endpoint
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
        project = "${var.tenant}-${var.environment}"
        source {
          repo_url        = var.app_repo_url
          target_revision = var.target_revision
          path            = "{{path}}"
          helm {
            value_files  = ["values-${var.environment}.yaml"]
            release_name = "{{path.basename}}"
            parameter {
              name  = "envs.EXAMPLE_VAR"
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
