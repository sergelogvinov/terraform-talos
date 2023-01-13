
output "name" {
  value = var.name
}

output "region" {
  description = "AWS regions"
  value       = var.region
}

output "tags" {
  value = var.tags
}

output "network" {
  description = "The network"
  value = {
    vpc_id = module.vpc.vpc_id
    zone = { for idx, zone in data.aws_availability_zones.zones.names : zone => {
      ids  = data.aws_availability_zones.zones.zone_ids[idx]
      name = zone

      intra_ids        = module.vpc.intra_subnets[idx]
      intra_subnets    = local.intra_subnets[idx]
      public_ids       = module.vpc.public_subnets[idx]
      public_subnets   = local.public_subnets[idx]
      private_ids      = module.vpc.private_subnets[idx]
      private_subnets  = local.private_subnets[idx]
      database_ids     = module.vpc.database_subnets[idx]
      database_subnets = local.database_subnets[idx]
    } }
  }
}
