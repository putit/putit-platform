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
- **ECR** — container registry per app (immutable tags, scan on push)
- **Nginx** — demo application
- **Echo-Server** — demo app deployed via ArgoCD + GitHub Actions CI/CD

## Repo Structure

```
├── .github/workflows/       # CI/CD pipelines (plan on PR, apply on merge, app builds)
├── apps/                    # Dockerized applications with Helm charts (ArgoCD auto-discovers)
│   └── echo-server/
│       ├── Dockerfile
│       └── charts/          # Helm chart (values.yaml, templates/)
├── charts/                  # Local Helm chart wrappers with extra templates
│   ├── nginx/
│   └── traefik/
├── modules/                 # Terraform modules (called by Terragrunt)
│   ├── argocd-config/
│   ├── argocd-server/
│   ├── ecr/
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

## Pre-Deployment Secrets

Before deploying ArgoCD, store the GitHub App private key in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name "sandbox/argocd-github-app-private-key" \
  --secret-string file://path/to/github-app-private-key.pem \
  --region eu-west-1
```

The ArgoCD module reads this secret during `terraform apply` and creates a Kubernetes secret with the proper ArgoCD labels. The IAM role used for Terraform execution (both local and CI) needs `secretsmanager:GetSecretValue` on this secret.

## Deployment Order

Apply modules in this order for a new cluster:

```bash
# 1. VPC
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/vpc apply

# 2. Data (Route53 zone lookup + ACM wildcard certificate)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/data apply

# 3. EKS Cluster
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/cluster apply

# 4. Namespaces
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/namespaces apply

# 5. IAM
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/iam apply

# 6. AWS Load Balancer Controller
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/aws-load-balancer-controller apply

# 7. External DNS
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/external-dns apply

# 8. Traefik Ingress
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/traefik-ingress apply

# 9. External Secrets
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/external-secret apply

# 10. Secret Manager (CSI Driver)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/secret-manager apply

# 11. Karpenter
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/karpenter apply

# 12. Monitoring (Prometheus + Grafana)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/monitoring apply

# 13. Logging (Loki + Alloy)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/logging apply

# 14. ArgoCD Server
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/argocd-server apply

# 15. ArgoCD Config
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/argocd-config apply

# 16. Nginx (demo app)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/eks/nginx apply

# 17. ECR (container registries for apps)
terragrunt --working-dir tenant/k8s/eu-west-1/sandbox/ecr apply
```

Or use `terragrunt run-all` from the sandbox root (dependency graph is respected):

```bash
terragrunt run-all apply --working-dir tenant/k8s/eu-west-1/sandbox --non-interactive
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

## Deploying Apps

Apps live in `apps/<name>/` with a Dockerfile and Helm chart. ArgoCD auto-discovers them via the git directory generator.

**Traffic flow:** Route53 → ALB (ACM TLS) → Traefik (NodePort) → IngressRoute → Service → Pod

### CI/CD Flow

1. Push changes to `apps/<name>/Dockerfile` or `apps/<name>/src/`
2. GitHub Actions builds Docker image and pushes to ECR
3. Workflow updates `image.tag` in `apps/<name>/charts/values.yaml` and commits
4. ArgoCD detects the change and syncs

### Adding a New App

1. Add name to `tenant/.../ecr/terragrunt.hcl` `app_names` list
2. Add name to `tenant/.../iam/terragrunt.hcl` `services` list
3. Create `apps/<name>/charts/` (Chart.yaml, values.yaml, templates/)
4. Create `apps/<name>/Dockerfile`
5. Add `.github/workflows/build-<name>.yml`
6. Apply ECR + IAM modules, push — ArgoCD auto-discovers

## Adding a New Environment

1. Create `tenant/k8s/<region>/<env-name>/env.hcl` with environment name
2. Copy the sandbox terragrunt structure
3. Update inputs as needed for the new environment
4. Run `bootstrap-state.sh` if using a new AWS account

## CI/CD

- **Pull Requests**: `terragrunt plan` runs automatically for changed modules
- **Merge to main**: `terragrunt apply` runs automatically
- Configure `AWS_ROLE_ARN` secret in GitHub repository settings
