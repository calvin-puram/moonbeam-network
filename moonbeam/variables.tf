variable "region" {
  type        = string
  description = "The AWS region to deploy resources"
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC cidr"
}

variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "preferred_number_of_public_subnets" {
  type        = number
  description = "Number of public subnets"
}

variable "preferred_number_of_private_subnets" {
  type        = number
  description = "Number of private subnets"
}



variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

variable "node_type" {
  type        = string
  description = "The type of node to create for polkadot nodes"
}

variable "path-to-node-config" {
  type        = string
  description = "Path to node cloud init config file"
  default     = "./files/moonbeam-cloud-init.yml"
}

# ========================================================= #
variable "instance_replicas" {
  type        = number
  description = "Number of replicas for this node type"
}

variable "zone" {
  type        = string
  description = "Availability zone that the instances will be created in"
}

variable "environment" {
  type        = string
  description = "Environment this instance will be running in"
  default     = "development"
}

variable "iteration" {
  type        = number
  description = "An identifier to separate similar networks"
}
