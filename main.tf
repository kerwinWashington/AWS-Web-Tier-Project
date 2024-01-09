resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "washington"
  }
}

resource "aws_subnet" "public" {
  count = var.publicSubnetCount
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = var.AZ[count.index]

  tags = {
    Name = "washington-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = var.publicSubnetCount
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + var.publicSubnetCount)
  availability_zone = var.AZ[count.index]

  tags = {
    Name = "washington-private-${count.index}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "washington-igw"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "nat-washington"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "nat-eip" {
  domain   = "vpc"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "washington-pub-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  count = var.publicSubnetCount
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "washington-priv-rt"
  }
}

resource "aws_route_table_association" "public-rt" {
  count = var.publicSubnetCount
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-rt" {
  count = var.publicSubnetCount
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}



