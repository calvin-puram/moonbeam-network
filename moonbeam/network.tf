# Create VPC
resource "aws_vpc" "blockops-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name = "${local.project_name}-network"
    }
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}


# Create public subnets
resource "aws_subnet" "public" {
  count                   = var.preferred_number_of_public_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_public_subnets
  vpc_id                  = aws_vpc.blockops-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.tags,
    {
      Name = format("${local.project_name}-PublicSubnet-%s", count.index + 1)
    }
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count      = var.preferred_number_of_private_subnets == null ? length(data.aws_availability_zones.available.names) : var.preferred_number_of_private_subnets
  vpc_id     = aws_vpc.blockops-vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  # map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.tags,
    {
      Name = format("${local.project_name}-PrivateSubnet-%s", count.index + 1)
    }
  )
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.blockops-vpc.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-%s!", aws_vpc.blockops-vpc.id, "IG")
    }
  )
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = format("%s-EIP", local.project_name)
    },
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(
    var.tags,
    {
      Name = format("%s-Nat", local.project_name)
    },
  )
}

# create private route table
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.blockops-vpc.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-Private-Route-Table", local.project_name)
    },
  )
}

# associate all private subnets to the private route table
resource "aws_route_table_association" "private-subnets-assoc" {
  count          = length(aws_subnet.private[*].id)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private-rtb.id
}

# create route table for the public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.blockops-vpc.id

  tags = merge(
    var.tags,
    {
      Name = format("%s-Public-Route-Table", local.project_name)
    },
  )
}

# create route for the public route table and attach the internet gateway
resource "aws_route" "public-rtb-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# associate all public subnets to the public route table
resource "aws_route_table_association" "public-subnets-assoc" {
  count          = length(aws_subnet.public[*].id)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public-rtb.id
}
