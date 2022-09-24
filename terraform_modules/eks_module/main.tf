locals {
  name            = var.cluster_name
  cluster_version = "1.21"
  region          = "us-east-1"

  tags = {
    Application = "teamsalertapi"
  }
}


resource "aws_iam_policy" "node_additional" {
  name        = "${local.name}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.28.0"

  cluster_name                    = local.name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  eks_managed_node_group_defaults = {
    iam_role_attach_cni_policy = false
    create_iam_role = false
    iam_role_arn=var.ec2noderole
  }
  self_managed_node_group_defaults = {

    iam_role_attach_cni_policy = false
    create_iam_role = false
    iam_role_arn=var.ec2noderole
  }


  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  create_iam_role          = false
  iam_role_arn = var.eksrole
  eks_managed_node_groups = {
    grp1 = {
      min_size     = 5
      max_size     = 7
      desired_size = 6

      instance_types = ["t2.medium"]
      labels = {
        Name    = "managed_node_groups"
      }
      tags = {
        ExtraTag = "grp1"
      }
    }
  }
  

  fargate_profile_defaults={
    iam_role_attach_cni_policy = false
    iam_role = var.fargatenoderole
    create_iam_role = false
    iam_role_arn=var.fargatenoderole
  }

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
          labels = {
            WorkerType = "fargate"
          }
        },
        {
          namespace = "monitoring"
          labels = {
            WorkerType = "fargate"
          }
        },
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        }
        #,{
        #  namespace = "harness-delegate-ng"
       # }
      ]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }

    secondary = {
      name = "secondary"
      selectors = [
        {
          namespace = "default"
          labels = {
            Environment = "dev"
          }
        }
      ]

      # Using specific subnets instead of the subnets supplied for the cluster itself
      subnet_ids = [var.subnet_ids[1]]

      tags = {
        Owner = "secondary"
      }
    }
  }

  tags = local.tags
}