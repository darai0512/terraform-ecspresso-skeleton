##################################################
# nat gateway

resource "aws_eip" "forwarder" {
  for_each = var.network.subnets
  domain   = "vpc"
}

resource "aws_nat_gateway" "forwarder" {
  for_each      = var.network.subnets
  allocation_id = aws_eip.forwarder[each.key].id
  subnet_id     = aws_subnet.if[each.key].id
}

##################################################
# subnet

resource "aws_route_table" "forwarder" {
  for_each = var.network.subnets
  vpc_id   = aws_vpc.sample.id
  route {
    cidr_block = var.network.vpc_cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.forwarder[each.key].id
  }
}

resource "aws_route_table_association" "forwarder" {
  for_each       = aws_subnet.forwarder
  subnet_id      = each.value.id
  route_table_id = aws_route_table.forwarder[each.key].id
}

resource "aws_subnet" "forwarder" {
  for_each          = var.network.subnets
  vpc_id            = aws_vpc.sample.id
  cidr_block        = each.value.mfwd
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tags = {
    Name = "forwarder-${each.key}"
  }
}

##################################################
# security group

resource "aws_security_group" "forwarder" {
  name   = "forwarder"
  vpc_id = aws_vpc.sample.id

  # app -> squid
  ingress {
    from_port       = 8888
    to_port         = 8888
    protocol        = "tcp"
    security_groups = [aws_security_group.app_egress.id]
  }

  # squid -> internet
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # squid -> vpce interface endpoints
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.vpce.id]
  }
}
