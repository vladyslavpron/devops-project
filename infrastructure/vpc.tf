resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main_public_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "main_public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}b"
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "main_private_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}a"
  cidr_block        = "10.0.3.0/24"
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main_public_rt_association" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.main_public_rt.id
}


resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.main_public_subnet.id
}

resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }
}

resource "aws_route_table_association" "main_private_rt_association" {
  subnet_id      = aws_subnet.main_private_subnet.id
  route_table_id = aws_route_table.main_private_rt.id
}