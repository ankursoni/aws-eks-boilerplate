locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com",
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "eks-node-role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com",
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_eks_cluster" "eks01" {
  name     = "${var.environment}-eks01"
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = var.subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController
  ]
}

resource "aws_launch_template" "ekslaunchtemplate" {
  name                   = "eks-managed-launchtemplate"
  vpc_security_group_ids = concat(var.vpc_security_group_ids, [aws_eks_cluster.eks01.vpc_config[0].cluster_security_group_id])

  tags = local.tags
}

resource "aws_eks_node_group" "eksng01" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version
  }

  scaling_config {
    desired_size = var.eks_managed_instance_desired_size
    min_size     = var.eks_managed_instance_min_size
    max_size     = var.eks_managed_instance_max_size
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types
  capacity_type  = var.eks_managed_capacity_type

  # commented for manually scaling out and scaling in
  # lifecycle {
  #   ignore_changes = [
  #     scaling_config[0].desired_size,
  #     scaling_config[0].max_size,
  #     scaling_config[0].min_size,
  #   ]
  # }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "owned"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}

# Enable iam roles for service accounts via oidc provider
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
data "tls_certificate" "ekstlsc01" {
  url = aws_eks_cluster.eks01.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "eksoidcprovider" {
  url             = aws_eks_cluster.eks01.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstlsc01.certificates[0].sha1_fingerprint]
}
resource "aws_iam_role" "eksiamrole" {
  name = "eks-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Federated = [aws_iam_openid_connect_provider.eksoidcprovider.arn]
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:sub" = ["system:serviceaccount:kube-system:aws-node"]
        }
      }
      Action = ["sts:AssumeRoleWithWebIdentity"]
    }
  })
}

# Create eks secrets manager role
# Reference: https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html
resource "aws_iam_role" "ekssecretsmanagerrole" {
  name = "eks-secrets-manager-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
        },
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:aud" : "sts.amazonaws.com",
          }
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      },
    ]
  })
}
resource "aws_iam_policy" "ekssecretsmanagerpolicy" {
  name = "eks-secretsmanager-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:demo-*"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ekssecretsmanagerroleattachment" {
  role       = aws_iam_role.ekssecretsmanagerrole.name
  policy_arn = aws_iam_policy.ekssecretsmanagerpolicy.arn
}

# Create eks iam load balancer role
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
resource "aws_iam_role" "ekslbrole" {
  name = "eks-load-balanacer-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
        },
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:aud" : "sts.amazonaws.com",
          }
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      },
    ]
  })
}
resource "aws_iam_policy" "albcontrollerpolicy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/awslbcontroller_policy.json")
}
resource "aws_iam_role_policy_attachment" "ekslbroleattachment01" {
  role       = aws_iam_role.ekslbrole.name
  policy_arn = aws_iam_policy.albcontrollerpolicy.arn
}
resource "aws_iam_role_policy_attachment" "ekslbroleattachment02" {
  role       = aws_iam_role.ekslbrole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

data "aws_caller_identity" "current" {}

# Create eks cluster autoscaler role
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html#cluster-autoscaler
resource "aws_iam_role" "eksclusterautoscalerrole" {
  name = "eks-cluster-autoscaler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
        },
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      },
    ]
  })
}
resource "aws_iam_policy" "eksclusterautoscalerpolicy" {
  name   = "AmazonEKSClusterAutoscalerPolicy"
  policy = replace(file("${path.module}/eks-cluster-autoscaler-policy.json"), "<my-cluster>", aws_eks_cluster.eks01.name)
}
resource "aws_iam_role_policy_attachment" "eksclusterautoscalerroleattachment01" {
  role       = aws_iam_role.eksclusterautoscalerrole.name
  policy_arn = aws_iam_policy.eksclusterautoscalerpolicy.arn
}

# # For pod based cloudwatch logging using iam role mapped to service account
# resource "aws_cloudwatch_log_group" "ekscloudwatchloggroup" {
#   # The log group name format is /aws/eks/<cluster-name>/cluster
#   # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
#   name              = "/aws/eks/${aws_eks_cluster.eks01.name}/cluster"
#   retention_in_days = 7

#   tags = local.tags
# }
# resource "aws_iam_role" "ekspodcloudwatchrole" {
#   name = "eks-pod-cloudwatch-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
#         },
#         Action = [
#           "sts:AssumeRoleWithWebIdentity"
#         ]
#       },
#     ]
#   })
# }
# resource "aws_iam_role_policy_attachment" "ekspod-CloudWatchAgentServerPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.ekspodcloudwatchrole.name
# }
