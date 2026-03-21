locals {
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr_block, 4, i)
  ]
  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr_block, 4, i + 8)
  ]

  # Build subnet maps keyed by AZ for for_each
  private_subnets = {
    for i, az in local.azs : az => {
      cidr  = local.private_subnet_cidrs[i]
      index = i + 1
    }
  }
  public_subnets = {
    for i, az in local.azs : az => {
      cidr  = local.public_subnet_cidrs[i]
      index = i + 1
    }
  }

  eks_private_tags = var.cluster_name != "" ? {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}

  eks_public_tags = var.cluster_name != "" ? {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = "${var.name}-vpc" })

  lifecycle {
    prevent_destroy = false # set to true in production
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(var.tags, local.eks_private_tags, {
    Name = "${var.name}-private-${each.value.index}"
    Tier = "private"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, local.eks_public_tags, {
    Name = "${var.name}-public-${each.value.index}"
    Tier = "public"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]

  tags = merge(var.tags, { Name = "${var.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(var.tags, { Name = "${var.name}-nat" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "default" {
  name        = "${var.name}-default-sg"
  description = "Default VPC SG: deny all inbound, allow all outbound"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-default-sg" })

  lifecycle {
    create_before_destroy = true
  }
}
