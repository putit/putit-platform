locals {
  cluster_name     = "${var.cluster_name_prefix}-${var.environment}"
}

module "irsa_role_ebs_addon" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "v5.39.1"
  role_name             = "ebs-csi-${var.environment}-${local.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.14.0"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  enable_irsa		  = true
  create_kms_key  = true
  cluster_endpoint_public_access = true
  # default false, if false nodes has to be able to access internet via NAT gw
  cluster_endpoint_private_access = true

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets_ids

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
  }

  # make the cluster creator an administrator, good enough for lab/play usage
  enable_cluster_creator_admin_permissions = true

# un comment and add ROLE_ARN to make that role a administrator
#  access_entries = {
#    # One access entry with a policy associated
#    admin = {
#      kubernetes_groups = []
#      principal_arn     = <ROLE_ARN>
#
#      policy_associations = {
#        admin = {
#          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#          access_scope = {
#            type       = "cluster"
#          }
#        }
#      }
#    }
#  }

#  eks_managed_node_groups = {
#    managed_node_group_1 = {
#      remote_access = {
#        ec2_ssh_key               = "platform-poc-sandbox"
#        source_security_group_ids = [aws_security_group.remote_access.id]
#      }
#      enable_bootstrap_user_data = true
#      use_custom_launch_template = false
#      
#      min_size     = 1
#      max_size     = 4
#      desired_size = 1
#
#      instance_types = ["t3.large"]
#      disk_size = 50
#      subnet_ids = var.private_subnets_ids
#      iam_role_additional_policies = {
#        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#        AWSLoadBalancerController = aws_iam_policy.aws_loadbalancer_controller_policy.arn
#      }
#    }
#    managed_node_group_2 = {
#      min_size     = 1
#      max_size     = 4
#      desired_size = 1
#      ami_id = "ami-0f17524429ac1df59"
#      instance_types = ["t3.large"]
#      disk_size = 50
#      subnet_ids = var.private_subnets_ids
#      enable_bootstrap_user_data = true
#      use_custom_launch_template = false
#      iam_role_additional_policies = {
#        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#        AWSLoadBalancerController = aws_iam_policy.aws_loadbalancer_controller_policy.arn
#      }
#    }
#  }
  self_managed_node_groups = {
    # Complete
    complete = {
      name            = "complete-self-mng"
      use_name_prefix = true

      subnet_ids = var.private_subnets_ids

      min_size     = 2
      max_size     = 4
      desired_size = 2

      ami_id = "ami-0f17524429ac1df59"

      instance_type = "t3.large"

      launch_template_name            = "self-managed-ex"
      launch_template_use_name_prefix = true
      launch_template_description     = "Self managed node group example launch template"

      ebs_optimized     = true
      enable_monitoring = false

      # uncomment to add such key to the EC2, please create it first
      # TODO find a way to do it with a module, mostly fetch private one
      #key_name = "platform-poc-sandbox"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      #enable_bootstrap_user_data = true

      create_iam_role          = true
      iam_role_name            = "self-managed-node-group-complete-example"
      iam_role_use_name_prefix = false
      iam_role_description     = "Self managed node group complete example role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        AWSLoadBalancerController = aws_iam_policy.aws_loadbalancer_controller_policy.arn
      }

      tags = {
        ExtraTag = "Self managed node group complete example"
      }
    }
  }

  
  # addons
  cluster_addons = {
    coredns = {
      most_recent = false
      addon_version = "v1.10.1-eksbuild.13"
    }
    kube-proxy = {
      most_recent = false
      addon_version = "v1.28.2-eksbuild.2"
    }
    vpc-cni = {
      most_recent = false
      addon_version = "v1.15.1-eksbuild.1"
    }
    aws-ebs-csi-driver = {
      most_recent = false
      addon_version = "v1.35.0-eksbuild.1"
      service_account_role_arn = module.irsa_role_ebs_addon.iam_role_arn
    }
  }
}

# tag subnets for loadbalancer-controller - move to ginger
resource "aws_ec2_tag" "private_subnet_internal_tag" {
  for_each    = toset(var.private_subnets_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag" {
  for_each    = toset(var.private_subnets_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "public_subnet_internal_tag" {
  for_each    = toset(var.public_subnets_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster_tag" {
  for_each    = toset(var.public_subnets_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "owned"
}

# remote access - debug
resource "aws_security_group" "remote_access" {
  name_prefix = "debug-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}


# AWS Load Balancer policy
resource "aws_iam_policy" "aws_loadbalancer_controller_policy" {
  name        = "aws-loadbalancer-controller-${local.cluster_name}"
  description = "AWS LoadBalancer Controller policy for version ${var.aws_loadbalancer_controller_app_version}"
  policy =  file("${path.module}/policies/${var.aws_loadbalancer_controller_app_version}/iam_policy.json")
}

# test it later SA for AWS Load Balancer
#module "vpc_cni_irsa" {
#  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  version = "~> 5.37"
#
#  role_name_prefix      = "VPC-CNI-IRSA"
#  attach_vpc_cni_policy = true
#  vpc_cni_enable_ipv4   = true # NOTE: This was what needed to be added
#
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-node"]
#    }
#  }
#}
