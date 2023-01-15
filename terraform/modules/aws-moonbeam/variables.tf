variable "machine_type" {
  type        = string
  description = "AWS machine type"
}

variable "region" {
  type        = string
  description = "The AWS region to deploy resources"
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

variable "node_type" {
  type        = string
  description = "The type of node to create for polkadot nodes"
}

variable "name" {
  description = "Node Name"
  type        = string
}

variable "node_count" {
  description = "Number of Nodes"
  type        = number
}

variable "data_disk_size" {
  type        = number
  description = "The size for the attached Data Disk"
}

variable "os_disk_size" {
  type        = number
  description = "The size for the OS Disk"
}

variable "instance_replicas" {
  type        = number
  description = "Number of replicas for this node type"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID of subnet to attach the network interface"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to attach the security group"
}

variable "snapshot_disks" {
  type = list(number)
}

variable "path-to-node-config" {
  type        = string
  description = "Path to node cloud init config file"

}

variable "key_path" {
  type        = string
  description = " ssh keyfile"
  default     = "~/.ssh/id_rsa.pub"
}


variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 30333, 30334, 9615, 9616, 9933, 9934, 9945, 9944, 9100]
}






