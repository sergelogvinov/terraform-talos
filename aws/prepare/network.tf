
locals {
  name = var.name
  azn  = length(data.aws_availability_zones.zones.names)
  azs  = data.aws_availability_zones.zones.names

  azblocks = [for idx in range(local.azn) : cidrsubnet(var.network_cidr, 8 - 2, var.network_shift + idx)]
  subnets  = [for idx in range(local.azn) : cidrsubnets(local.azblocks[idx], 2, 2, 2, 2)]

  intra_subnets    = [for cidr in local.subnets : cidr[0]]
  public_subnets   = [for cidr in local.subnets : cidr[1]]
  private_subnets  = [for cidr in local.subnets : cidr[2]]
  database_subnets = [for cidr in local.subnets : cidr[3]]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"

  name = local.name
  cidr = var.network_cidr

  azs              = local.azs
  intra_subnets    = local.intra_subnets
  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  single_nat_gateway   = true
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group   = false
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  tags = merge(var.tags, {
    "kubernetes.io/cluster/${local.name}" = "shared"
  })

  public_subnet_tags = {
    Name                     = "${local.name}-public"
    destination              = "public"
    "kubernetes.io/role/elb" = "1"
  }
  public_route_table_tags = {
    Name        = "${local.name}-public"
    destination = "public"
  }

  private_subnet_tags = {
    Name                              = "${local.name}-private"
    destination                       = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }
  private_route_table_tags = {
    Name        = "${local.name}-private"
    destination = "private"
  }

  database_subnet_tags = {
    Name        = "${local.name}-database"
    destination = "database"
  }
  database_route_table_tags = {
    Name        = "${local.name}-database"
    destination = "database"
  }

  intra_subnet_tags = {
    Name        = "${local.name}-intra"
    destination = "intra"
  }
  intra_route_table_tags = {
    Name        = "${local.name}-intra"
    destination = "intra"
  }
}

# module "vpc_gateway_endpoints" {
#   source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
#   version = "3.18.1"

#   vpc_id = module.vpc.vpc_id

#   endpoints = {
#     s3 = {
#       service      = "s3"
#       service_type = "Gateway"
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-s3"
#       }
#     },

#     # https://aws.github.io/aws-eks-best-practices/karpenter/
#     ec2 = {
#       service             = "ec2"
#       service_type        = "Interface"
#       private_dns_enabled = true
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-ec2"
#       }
#     },
#     ecr_dkr = {
#       service      = "ecr.dkr"
#       service_type = "Interface"
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-ecr-dkr"
#       }
#     },
#     ecr_api = {
#       service      = "ecr.api"
#       service_type = "Interface"
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-ecr-api"
#       }
#     },
#     ssm = {
#       service             = "ssm"
#       service_type        = "Interface"
#       private_dns_enabled = true
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-ssm"
#       }
#     },
#     sts = {
#       service      = "sts"
#       service_type = "Interface"
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-sts"
#       }
#     },

#     sqs = {
#       service             = "sqs"
#       service_type        = "Interface"
#       private_dns_enabled = true
#       route_table_ids = flatten([
#         module.vpc.private_route_table_ids,
#         module.vpc.public_route_table_ids
#       ])
#       tags = {
#         Name = "${local.name}-sqs"
#       }
#     },
#   }

#   tags = var.tags
# }
