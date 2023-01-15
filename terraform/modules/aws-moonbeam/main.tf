# v0.1.0


# Container optimized image
data "aws_ami" "cos_lts" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["moonbase-*"]
  }
}

# Template file for Cloud Init
data "template_file" "cloud_init_file" {

  template = file("${var.path-to-node-config}")

}

# Persistent Data Disk Creation
resource "aws_ebs_volume" "blockops_compute_data_disk" {

  count = var.instance_replicas

  type              = "gp3"
  availability_zone = var.zone
  size              = var.data_disk_size

  tags = {
    Name        = "${var.environment}${var.iteration}-${var.node_type}-data-${format("%03d", count.index + 1)}"
    environment = var.environment
  }

  # prevent data disks from getting deleted as we need to keep it
  lifecycle {

    prevent_destroy = false

  }

}

# Role for Data Lifecycle Manager to Create Snapshots
resource "aws_iam_role" "dlm_lifecycle_role" {
  name = "dlm-lifecycle-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "dlm.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Data Life Cycle Manager Role Policy Association
resource "aws_iam_role_policy" "dlm_lifecycle" {

  count = length(var.snapshot_disks) > 0 ? 1 : 0
  name  = "dlm-lifecycle-policy"
  role  = aws_iam_role.dlm_lifecycle_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:CreateTags"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ec2:*::snapshot/*"
      }
    ]
  })
}

# Persistent Data Snapshot
resource "aws_dlm_lifecycle_policy" "disk_snapshot_policy" {
  count              = length(var.snapshot_disks) > 0 ? 1 : 0
  description        = "DLM lifecycle policy for data disk snapshots"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    policy_type    = "EBS_SNAPSHOT_MANAGEMENT"

    schedule {
      name = "1 year of daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["00:00"]
      }

      retain_rule {
        count = 365
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = {
      environment = var.environment
    }

  }
}

# Persistent Data DiskAttachment
resource "aws_volume_attachment" "blockops_compute_data_disk_att" {
  count       = length(var.snapshot_disks)
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.blockops_compute_data_disk[count.index].id
  instance_id = aws_instance.blockops_node[count.index].id
}

resource "aws_network_interface" "blockops_node_interface" {
  count           = var.instance_replicas
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.blockops-sg.id]

  tags = {
    "Name" = "${var.environment}${var.iteration}-${var.node_type}-${format("%03d", count.index + 1)}"
  }
}


resource "aws_security_group" "blockops-sg" {
  vpc_id      = var.vpc_id
  name        = "${var.name}-sg"
  description = "security group that allows ports and all egress traffic"


  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-ssh"
  }

}


resource "aws_instance" "blockops_node" {
  count             = var.instance_replicas
  ami               = data.aws_ami.cos_lts.id
  instance_type     = var.machine_type
  availability_zone = var.zone
  key_name          = aws_key_pair.blockops_key.key_name

  root_block_device {
    volume_size           = var.os_disk_size
    volume_type           = "gp3"
    delete_on_termination = true

    tags = {
      Environment = "${var.environment}"

    }
  }

  network_interface {
    network_interface_id = aws_network_interface.blockops_node_interface[count.index].id
    device_index         = 0

  }

  user_data = data.template_file.cloud_init_file.rendered
  tags = {


    Name        = "${var.environment}${var.iteration}-${var.node_type}-${format("%03d", count.index + 1)}"
    environment = "${var.environment}${var.iteration}"
    managed     = "terraform-ansible"
    node_type   = var.node_type

  }
}

resource "aws_eip" "blockops-node-ip" {
  count    = 1 #var.instance_replicas
  instance = aws_instance.blockops_node[count.index].id
  vpc      = true

  tags = {
    "Name" = "${var.environment}${var.iteration}-${var.node_type}-${format("%03d", count.index + 1)}"
  }
}


resource "aws_key_pair" "blockops_key" {
  key_name   = "blockops"
  public_key = file(var.key_path)
}
