data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.env}-vpc"
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.env}-igw"
    Environment = var.env
  }
}

resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project}-${var.env}-public-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project}-${var.env}-private-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project}-${var.env}-public-rt"
    Environment = var.env
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  domain = "vpc"

  tags = {
    Name        = "${var.project}-${var.env}-nat-eip-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.project}-${var.env}-nat-gw-${count.index + 1}"
    Environment = var.env
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[var.single_nat_gateway ? 0 : count.index].id : null
  }

  tags = {
    Name        = "${var.project}-${var.env}-private-rt-${count.index + 1}"
    Environment = var.env
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name_prefix = "${var.project}-${var.env}-vpce-"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
    description = "HTTPS from VPC CIDR"
  }

  tags = {
    Name        = "${var.project}-${var.env}-vpce-sg"
    Environment = var.env
  }
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_vpc_endpoints && contains(var.vpc_endpoint_services, "s3") ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = {
    Name        = "${var.project}-${var.env}-s3-endpoint"
    Environment = var.env
  }
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count             = var.enable_vpc_endpoints && contains(var.vpc_endpoint_services, "dynamodb") ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = {
    Name        = "${var.project}-${var.env}-dynamodb-endpoint"
    Environment = var.env
  }
}

# Interface Endpoints
resource "aws_vpc_endpoint" "interface_endpoints" {
  for_each = var.enable_vpc_endpoints ? {
    for service in var.vpc_endpoint_services : service => service
    if service != "s3" && service != "dynamodb"
  } : {}

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  tags = {
    Name        = "${var.project}-${var.env}-${each.value}-endpoint"
    Environment = var.env
  }
}
