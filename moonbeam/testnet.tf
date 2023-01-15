locals {
  project_name           = "moonriver"
  default_machine_type   = "t2.xlarge"
  zone                   = var.zone
  region                 = "eu-central-1"
  default_data_disk_size = 50
  node_type              = var.node_type
  node-config-paths      = var.path-to-node-config
  node_machine_type      = "t2.xlarge"
  node_disk_size         = "50"
  node_os_disk_size      = "30"
  disk_snapshots         = []
}

module "moonbeam" {
  name                = local.project_name
  source              = "../terraform/modules/aws-moonbeam"
  environment         = var.environment
  iteration           = var.iteration
  zone                = local.zone
  region              = local.region
  node_type           = var.node_type
  subnet_id           = aws_subnet.public[0].id
  vpc_id              = aws_vpc.blockops-vpc.id
  data_disk_size      = local.node_disk_size
  os_disk_size        = local.node_os_disk_size
  instance_replicas   = var.instance_replicas
  snapshot_disks      = local.disk_snapshots
  machine_type        = local.node_machine_type
  path-to-node-config = local.node-config-paths
  node_count          = 1
}
