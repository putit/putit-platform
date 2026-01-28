## kube-prometheus-stack values

grafana:
  adminPassword: "${grafana_admin_password}"
  persistence:
    enabled: true
    size: "${grafana_storage_size}"
    storageClassName: "${storage_class}"
  ingress:
    enabled: ${grafana_ingress_enabled}
    %{ if grafana_ingress_enabled }
    hosts:
      - ${grafana_host}
    %{ endif }
  additionalDataSources:
    - name: Loki
      type: loki
      access: proxy
      url: "${loki_url}"
      isDefault: false

prometheus:
  prometheusSpec:
    retention: "${prometheus_retention}"
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: "${storage_class}"
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: "${prometheus_storage_size}"
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        memory: 4Gi

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: "${storage_class}"
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true

defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false
    configReloaders: true
    general: true
    k8s: true
    kubeApiserverAvailability: true
    kubeApiserverBurnrate: true
    kubeApiserverHistogram: true
    kubeApiserverSlos: true
    kubeControllerManager: false
    kubelet: true
    kubeProxy: false
    kubePrometheusGeneral: true
    kubePrometheusNodeRecording: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
    network: true
    node: true
    nodeExporterAlerting: true
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true
