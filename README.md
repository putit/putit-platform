# Overview

- EKS cluster deployed into VPC
- application installed on the cluster
  - aws-loadbalancer-controller - to spin up ALB for traefik ingress
  - traefik - which behaves as an ingress
  - nginx - which is our demo app behind dsi-gateway
  - argocd - for the future to prove that we can make it working with Github action in cicd
  - external-dns - manage DNS in route53 for both domains technipfmc.com and .service
  - external-secret - allows POD to obtain secrets from AWS Secret Manager

# TODO
 - move default namespace to be a === environment,
 - check argocd server and config and add github discovery generator
 - add monitoring with promethues stack and grafana
 - add opensearch module and logs


## Repo strucutre

```
├── charts
│   ├── nginx
│   │   ├── charts
│   │   └── templates
│   └── traefik
│       ├── charts
│       └── templates
├── modules
│   ├── argocd-config
│   ├── argocd-server
│   │   └── values
│   ├── eks
│   │   └── policies
│   │       └── v2.7.1
│   ├── external-dns
│   │   ├── policies
│   │   └── values
│   ├── helm-hash
│   ├── iam
│   │   └── policies
│   ├── k8s-namespaces
│   ├── nginx
│   │   └── values
│   ├── traefik-ingress
│   │   ├── policies
│   │   └── values
│   └── vpc
└── tenant
    └── k8s
        └── eu-west-1
            └── sandbox
                ├── eks
                │   ├── argocd-config
                │   ├── argocd-server
                │   ├── aws-load-balancer-controller
                │   ├── cluster
                │   ├── data
                │   ├── external-dns
                │   ├── namespaces
                │   ├── nginx
                │   └── traefik-ingress
                ├── iam
                └── vpc
```

### Charts 
Here are some addiontal templates the the open source charts. 

### Modules
Terraform code, which should be versioned outside main repository. Those modules are being called by terragrunt.

### Tenant
Name of the logical group of environments.

## Usage

To provsion the EKS cluster we have to run terragrunt command AFTER ginger has been applied.
```
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/vpc apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/data apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/cluster apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/iam apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/external-dns apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/aws-load-balancer-controller apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/traefik-ingress apply
terragrunt --terragrunt-working-dir=tenant/k8s/eu-west-1/sandbox/eks/nginx apply
```

Update your kubeconfig, by adding the cluster into it.

Get the cluster name
```
aws eks list-clusters --profile $AWS_PROFILE --region $AWS_REGION
```

Add the cluster to the kubeconfig
```
aws eks update-kubeconfig --region $AWS_REGION --name <CLUSTER_NAME>
```
