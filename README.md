# putit-platform

EKS cluster deployed into VPC with supporting services managed via Terraform/Terragrunt.

## Components

- **EKS Cluster** — Kubernetes v1.30, self-managed node groups, EBS CSI driver, IRSA
- **AWS Load Balancer Controller** — provisions ALBs for ingress
- **Traefik** — ingress controller behind dual ALB (internal + public)
- **External-DNS** — manages DNS records in Route53
- **External-Secrets** — syncs AWS Secrets Manager secrets to Kubernetes
- **Secrets Store CSI Driver** — mounts secrets as volumes
- **Karpenter** — auto-scales nodes based on workload demand
- **ArgoCD** — GitOps continuous delivery with GitHub integration
- **Monitoring** — kube-prometheus-stack (Prometheus, Grafana, AlertManager, node-exporter, kube-state-metrics)
- **Logging** — Grafana Loki (log storage) + Grafana Alloy (log collector DaemonSet)
- **Nginx** — demo application

## Repo Structure

```
├── .github/workflows/       # CI/CD pipelines (plan on PR, apply on merge)
├── charts/                  # Local Helm chart wrappers with extra templates
│   ├── nginx/
│   └── traefik/
├── modules/                 # Terraform modules (called by Terragrunt)
│   ├── argocd-config/
│   ├── argocd-server/
│   ├── aws-load-balancer-controller/
│   ├── eks/
│   ├── external-dns/
│   ├── external-secret/
│   ├── helm-hash/
│   ├── iam/
│   ├── k8s-namespaces/
│   ├── karpenter/
│   ├── logging/
│   ├── monitoring/
│   ├── nginx/
│   ├── secret-manager/
│   ├── traefik-ingress/
│   └── vpc/
├── scripts/                 # Operational scripts
│   └── bootstrap-state.sh   # Create S3 bucket + DynamoDB for TF state
└── tenant/                  # Terragrunt environment configs
    └── k8s/
        └── eu-west-1/
            └── sandbox/
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.9
- Terragrunt >= 0.68
- kubectl
- Helm 3

## Bootstrap (New Account)

Create the S3 state bucket and DynamoDB lock table:

```bash
./scripts/bootstrap-state.sh eu-west-1
```

## Deployment Order

Apply modules in this order for a new cluster:

```bash
# 1. VPC
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/vpc apply

# 2. Data (Route53 zone lookup)
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/data apply

# 3. EKS Cluster
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/cluster apply

# 4. Namespaces
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/namespaces apply

# 5. IAM
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/iam apply

# 6. AWS Load Balancer Controller
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/aws-load-balancer-controller apply

# 7. External DNS
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/external-dns apply

# 8. Traefik Ingress
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/traefik-ingress apply

# 9. External Secrets
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/external-secret apply

# 10. Secret Manager (CSI Driver)
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/secret-manager apply

# 11. Karpenter
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/karpenter apply

# 12. Monitoring (Prometheus + Grafana)
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/monitoring apply

# 13. Logging (Loki + Alloy)
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/logging apply

# 14. ArgoCD Server
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/argocd-server apply

# 15. ArgoCD Config
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/argocd-config apply

# 16. Nginx (demo app)
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/nginx apply
```

Or use `terragrunt run-all` from the sandbox root (dependency graph is respected):

```bash
terragrunt run-all apply --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox --terragrunt-non-interactive
```

## Post-Deployment

Update kubeconfig:

```bash
aws eks list-clusters --region eu-west-1
aws eks update-kubeconfig --region eu-west-1 --name <CLUSTER_NAME>
```

Retrieve ArgoCD admin password:

```bash
# From Kubernetes
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# From AWS Secrets Manager (if deployed)
aws secretsmanager get-secret-value --secret-id sandbox/argocd-admin-password --query SecretString --output text
```

Access Grafana:

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# Default credentials: admin / admin (change on first login)
```

Verify logs in Grafana:
- Open Grafana > Explore > Select Loki datasource
- Query: `{namespace="default"}`

## Adding a New Environment

1. Create `tenant/k8s/<region>/<env-name>/env.hcl` with environment name
2. Copy the sandbox terragrunt structure
3. Update inputs as needed for the new environment
4. Run `bootstrap-state.sh` if using a new AWS account

## CI/CD

- **Pull Requests**: `terragrunt plan` runs automatically for changed modules
- **Merge to main**: `terragrunt apply` runs automatically
- Configure `AWS_ROLE_ARN` secret in GitHub repository settings
