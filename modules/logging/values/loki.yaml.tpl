## Loki Helm values

deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  %{ if storage_backend == "filesystem" }
  storage:
    type: filesystem
  %{ endif }
  %{ if storage_backend == "s3" }
  storage:
    type: s3
    s3:
      s3: s3://${s3_region}/${s3_bucket}
      s3ForcePathStyle: true
  %{ endif }
  limits_config:
    retention_period: "${retention}"
  compactor:
    retention_enabled: true

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: "${storage_size}"
    storageClass: "${storage_class}"
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      memory: 1Gi

# Disable components not needed in SingleBinary mode
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

gateway:
  enabled: false

chunksCache:
  enabled: false

resultsCache:
  enabled: false

test:
  enabled: false
