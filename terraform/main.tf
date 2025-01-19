provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

# VPC
resource "aws_vpc" "technical_test_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "technical-test-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "technical_test_internet_gateway" {
  vpc_id = aws_vpc.technical_test_vpc.id
  tags = {
    Name = "technical-test-internet-gateway"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "technical_test_eip" {
  vpc = true
  tags = {
    Name = "technical-test-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "technical_test_nat_gateway" {
  allocation_id = aws_eip.technical_test_eip.id
  subnet_id     = aws_subnet.technical_test_public.id
  tags = {
    Name = "technical-test-nat-gateway"
  }
}

# Public Subnet
resource "aws_subnet" "technical_test_public" {
  vpc_id                  = aws_vpc.technical_test_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "technical-test-public"
  }
}

# Private Subnet
resource "aws_subnet" "technical_test_private" {
  vpc_id            = aws_vpc.technical_test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "technical-test-private"
  }
}

# Route Table
resource "aws_route_table" "technical_test_route_table" {
  vpc_id = aws_vpc.technical_test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.technical_test_internet_gateway.id
  }

  tags = {
    Name = "technical-test-routing-table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.technical_test_public.id
  route_table_id = aws_route_table.technical_test_route_table.id
}

# Security Groups
resource "aws_security_group" "ariane_security_group" {
  vpc_id = aws_vpc.technical_test_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["82.11.22.33/32", "81.44.55.87/32", "87.12.33.88/32"]
    description = "Allow HTTPS traffic from specific sources"
  }
# Required SG for Ansible from my Network
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["196.179.246.130/32"]
    description = "Allow SSH traffic from my network"
  }
# Required SG for Ansible from ariane (Bastion) to ariane it self
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
    description = "Allow SSH traffic from the instance it self"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "technical-test-ariane-security-group"
  }
}

resource "aws_security_group" "falcon_security_group" {
  vpc_id = aws_vpc.technical_test_vpc.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.ariane_security_group.id]
    description     = "Allow HTTP traffic from Ariane security group"
  }
# Required SG for Ansible from ariane (Bastion) to Falcon
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ariane_security_group.id]
    description     = "Allow SSH traffic from Ariane security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "technical-test-falcon-security-group"
  }
}

resource "aws_security_group" "redis_security_group" {
  vpc_id = aws_vpc.technical_test_vpc.id

  ingress {
    from_port       = 6399
    to_port         = 6399
    protocol        = "tcp"
    security_groups = [aws_security_group.falcon_security_group.id]
    description     = "Allow HTTP traffic from Falcon security group"
  }
# Required SG for Ansible from ariane (Bastion) to Redis
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ariane_security_group.id]
    description     = "Allow SSH traffic from Ariane security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "technical-test-redis-security-group"
  }
}

# EC2 Instances
resource "aws_instance" "ariane" {
  ami           = "ami-0df8c184d5f6ae949" 
  instance_type = "t2.micro"
  key_name      = "hamdi-key"
  subnet_id     = aws_subnet.technical_test_public.id
  security_groups = [aws_security_group.ariane_security_group.id]

  tags = {
    Name = "technical-test-ariane"
  }
}

resource "aws_instance" "falcon" {
  ami           = "ami-0df8c184d5f6ae949" 
  instance_type = "t2.micro"
  key_name      = "hamdi-key"
  subnet_id     = aws_subnet.technical_test_private.id
  security_groups = [aws_security_group.falcon_security_group.id]

  tags = {
    Name = "technical-test-falcon"
  }
}

resource "aws_instance" "redis" {
  ami           = "ami-0df8c184d5f6ae949" 
  instance_type = "t2.micro"
  key_name      = "hamdi-key"
  subnet_id     = aws_subnet.technical_test_private.id
  security_groups = [aws_security_group.redis_security_group.id]

  tags = {
    Name = "technical-test-redis"
  }
}
## This is required to allow the installation of docker on private instances (falcon and redis)
# Private Subnet Route Table
resource "aws_route_table" "technical_test_private_route_table" {
  vpc_id = aws_vpc.technical_test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.technical_test_nat_gateway.id
  }

  tags = {
    Name = "technical-test-private-routing-table"
  }
}

# Associate Route Table with Private Subnet
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.technical_test_private.id
  route_table_id = aws_route_table.technical_test_private_route_table.id
}
