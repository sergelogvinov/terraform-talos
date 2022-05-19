
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "network_internal" {
  description = "Internal network"
}

variable "instance_resource_group" {
  description = "Server Group"
  type        = string
  default     = ""
}

variable "instance_availability_set" {
  description = "Server availability set"
  type        = string
  default     = ""
}

variable "instance_count" {
  description = "Instances in region"
  type        = number
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "instance_image" {
  description = "Instance image"
  type        = string
  default     = ""
}

variable "instance_tags" {
  description = "Tags of resources"
  type        = map(string)
  default     = {}
}

variable "instance_secgroup" {
  description = "Instance network security group"
  type        = string
  default     = ""
}

variable "instance_params" {
  description = "Instance template parameters"
  type        = map(string)
}

variable "instance_ip_start" {
  description = "Instances ip begin from"
  type        = number
  default     = 11
}
