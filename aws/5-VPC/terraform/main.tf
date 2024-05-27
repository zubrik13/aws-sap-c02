# vpc
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Custom VPC"
  }
}

resource "aws_subnet" "subnet_public_1A" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Custom VPC Public Subnet 1A"
  }
}

resource "aws_subnet" "subnet_public_1B" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Custom VPC Public Subnet 1B"
  }
}

resource "aws_subnet" "subnet_private_1A" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  tags = {
    Name = "Custom VPC Private Subnet 1A"
  }
}

resource "aws_subnet" "subnet_private_1B" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  tags = {
    Name = "Custom VPC Private Subnet 1B"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Custom VPC IGW"
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Custom VPC Main RT"
  }
}

resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Custom VPC Private RT"
  }
}

resource "aws_route_table_association" "rta_subnet_public_1A" {
  subnet_id      = aws_subnet.subnet_public_1A.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_subnet_public_1B" {
  subnet_id      = aws_subnet.subnet_public_1B.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_subnet_private_1A" {
  subnet_id      = aws_subnet.subnet_private_1A.id
  route_table_id = aws_route_table.rtb_private.id
}

resource "aws_route_table_association" "rta_subnet_private_1B" {
  subnet_id      = aws_subnet.subnet_private_1B.id
  route_table_id = aws_route_table.rtb_private.id
}

# ec2
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

## sg
resource "aws_security_group" "sg_public" {
  name   = "sg_public"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_private" {
  name   = "sg_private"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.sg_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## key pair
resource "aws_key_pair" "ec2_ssh_key" {
  key_name   = "ec2-orbit-key"
  public_key = file("~/.ssh/ec2-orbit-key.pub")
}

## ec2 instances
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public_1A.id
  vpc_security_group_ids      = [aws_security_group.sg_public.id]
  associate_public_ip_address = true
  user_data                   = templatefile("${path.module}/user_data.tftpl", {})
  key_name = aws_key_pair.ec2_ssh_key.key_name

  tags = {
    Name = "Web server"
  }
}

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_private_1A.id
  vpc_security_group_ids      = [aws_security_group.sg_private.id]
  associate_public_ip_address = false
  key_name = aws_key_pair.ec2_ssh_key.key_name

  tags = {
    Name = "Backend server"
  }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_public_1A.id

  tags = {
    Name = "nat-gateway"
  }
}