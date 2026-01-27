## Grafana Alloy Helm values

alloy:
  configMap:
    content: |
      // Discover Kubernetes pods
      discovery.kubernetes "pods" {
        role = "pod"
      }

      // Relabel discovered targets
      discovery.relabel "pod_logs" {
        targets = discovery.kubernetes.pods.targets

        rule {
          source_labels = ["__meta_kubernetes_namespace"]
          target_label  = "namespace"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_name"]
          target_label  = "pod"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_container_name"]
          target_label  = "container"
        }
        rule {
          source_labels = ["__meta_kubernetes_namespace", "__meta_kubernetes_pod_name"]
          separator     = "/"
          target_label  = "job"
        }
        rule {
          source_labels = ["__meta_kubernetes_pod_node_name"]
          target_label  = "node"
        }
      }

      // Collect logs from discovered pods
      loki.source.kubernetes "pod_logs" {
        targets    = discovery.relabel.pod_logs.output
        forward_to = [loki.process.pod_logs.receiver]
      }

      // Process and enrich logs
      loki.process "pod_logs" {
        stage.static_labels {
          values = {
            cluster = "${cluster_name}",
          }
        }
        forward_to = [loki.write.default.receiver]
      }

      // Ship logs to Loki
      loki.write "default" {
        endpoint {
          url = "${loki_endpoint}"
        }
      }

controller:
  type: daemonset

resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    memory: 512Mi
