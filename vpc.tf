resource "aws_vpc" "sample" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  cidr_block           = var.network.vpc_cidr_block
  tags = {
    Name = "sample-${terraform.workspace}"
  }
}
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.sample.id
  # default sgのルールを空で維持するためにtf管理
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.sample.default_route_table_id
}

resource "aws_network_acl" "outer" {
  vpc_id = aws_vpc.sample.id
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_network_acl" "inner" {
  vpc_id = aws_vpc.sample.id
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = var.network.vpc_cidr_block
  }

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    from_port  = 0
    to_port    = 0
    cidr_block = var.network.vpc_cidr_block
  }

}
resource "aws_route_table" "inner" {
  vpc_id = aws_vpc.sample.id
  route {
    cidr_block = var.network.vpc_cidr_block
    gateway_id = "local"
  }
}
