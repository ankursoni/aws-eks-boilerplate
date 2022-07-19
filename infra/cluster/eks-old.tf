# locals {
#   tags = {
#     managed-by  = "terraform"
#     environment = var.environment
#   }
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 18.26.3"

#   cluster_name                    = "${var.environment}-eks01"
#   cluster_version                 = var.eks_kubernetes_version
#   vpc_id                          = var.vpc_id
#   subnet_ids                      = var.subnets
#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true
#   # manage_aws_auth_configmap       = true

#   # Extend cluster security group rules
#   cluster_security_group_additional_rules = {
#     egress_nodes_ephemeral_ports_tcp = {
#       description                = "To node 1025-65535"
#       protocol                   = "tcp"
#       from_port                  = 1025
#       to_port                    = 65535
#       type                       = "egress"
#       source_node_security_group = true
#     }
#   }

#   # Extend node-to-node security group rules
#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
#     egress_all = {
#       description = "Node all egress"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "egress"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   eks_managed_node_group_defaults = {
#     disk_size                             = 50
#     attach_cluster_primary_security_group = true
#     # We are using the IRSA created below for permissions
#     # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
#     # and then turn this off after the cluster/node group is created. Without this initial policy,
#     # the VPC CNI fails to assign IPs and nodes cannot join the cluster
#     # See https://github.com/aws/containers-roadmap/issues/1666 for more context
#     iam_role_attach_cni_policy = true
#   }
#   eks_managed_node_groups = {
#     eks-managed = {
#       create_launch_template = false
#       launch_template_name   = ""
#       min_size               = var.eks_managed_instance_min_size
#       max_size               = var.eks_managed_instance_max_size
#       desired_size           = var.eks_managed_instance_desired_size
#       instance_types         = var.eks_managed_instance_types
#       capacity_type          = var.eks_managed_capacity_type
#     }
#   }

#   cluster_addons = {
#     coredns = {
#       resolve_conflicts = "OVERWRITE"
#     }
#     kube-proxy = {}
#     vpc-cni = {
#       resolve_conflicts = "OVERWRITE"
#     }
#   }

#   tags = local.tags
# }

# # workaround for https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/faq.md#i-received-an-error-error-invalid-for_each-argument-
# resource "aws_iam_role_policy_attachment" "additional" {
#   for_each = module.eks.eks_managed_node_groups

#   policy_arn = aws_iam_policy.node_additional.arn
#   role       = each.value.iam_role_name
# }

# resource "aws_iam_policy" "node_additional" {
#   name        = "eks-node-additional"
#   description = "Example usage of node additional policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ec2:Describe*",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })

#   tags = local.tags
# }
