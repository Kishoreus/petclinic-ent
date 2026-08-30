resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name                                         = "${var.project_name}-public-${var.azs[count.index]}"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    "kubernetes.io/role/elb"                     = "1"
  })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, {
    Name                                         = "${var.project_name}-private-${var.azs[count.index]}"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    "kubernetes.io/role/internal-elb"            = "1"
  })
}

# --- NAT: single shared gateway (default) or one per AZ (HA) ---
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  domain = "vpc"
  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${count.index}"
  })
}

resource "aws_nat_gateway" "nat" {
  count         = var.single_nat_gateway ? 1 : length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-${count.index}"
  })
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.azs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id
  }
  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt-${count.index}"
  })
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "eice" {
  name        = "${var.project_name}-eice-sg"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.main.id
  egress {
    description = "Allow SSH to EKS worker nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-eice-sg"
  })
}
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}

resource "aws_ec2_instance_connect_endpoint" "eks" {
  subnet_id          = aws_subnet.private[0].id
  security_group_ids = [aws_security_group.eice.id]


  tags = merge(var.tags, {
    Name = "${var.project_name}-eice"
  })
}
