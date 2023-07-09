resource "aws_vpc" "main" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-vpc"}),
    tomap({"kubernetes.io/cluster/${var.prefix}-cluster" = "shared"})
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-igw"})
  )
}

#####################################################
#Public Subnets
#####################################################

resource "aws_subnet" "public_a" {
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "${data.aws_region.current.name}a"

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-a"}),
    tomap({"kubernetes.io/cluster/${var.prefix}-cluster" = "shared"}),
    tomap({"kubernetes.io/role/elb" = "1"})
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public"})
  )
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_eip" "public_a" {
  vpc = true

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-a"})
  )
}

resource "aws_nat_gateway" "public_a" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.public_a.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-a"})
  )
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "${data.aws_region.current.name}b"

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-b"}),
    tomap({"kubernetes.io/cluster/${var.prefix}-cluster" = "shared"}),
    tomap({"kubernetes.io/role/elb" = "1"})
  )
}

resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_b.id
}

resource "aws_eip" "public_b" {
  vpc = true

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-b"})
  )
}

resource "aws_nat_gateway" "public_b" {
  allocation_id = aws_eip.public_b.id
  subnet_id     = aws_subnet.public_b.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-public-b"})
  )
}

#####################################################
#Private Subnets
#####################################################

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-private-a1"}),
    tomap({"kubernetes.io/cluster/${var.prefix}-cluster" = "shared"}),
    tomap({"kubernetes.io/role/internal-elb" = "1"})
  )
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-private-a"})
  )
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route" "private_a_internet_out" {
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_a.id
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "${data.aws_region.current.name}b"

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-private-b"}),
    tomap({"kubernetes.io/cluster/${var.prefix}-cluster" = "shared"}),
    tomap({"kubernetes.io/role/internal-elb" = "1"})
  )
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    tomap({"Name" = "${var.prefix}-private-b"})
  )
}

resource "aws_route_table_association" "private_b" {
  route_table_id = aws_route_table.private_b.id
  subnet_id      = aws_subnet.private_b.id
}

resource "aws_route" "private_b_internet_out" {
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.public_b.id
}