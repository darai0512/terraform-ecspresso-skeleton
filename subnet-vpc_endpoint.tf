##############################################################
# VPC Endpoint全般とInterface EndpointのENIが所属するsubnet
##############################################################

##################################################
# gateway endpoint

resource "aws_vpc_endpoint" "s3" {
  tags = {
    Name = "s3"
  }
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.sample.id
  route_table_ids = flatten([
    aws_route_table.if.id,
    aws_route_table.inner.id,
    values(aws_route_table.forwarder)[*].id
  ])
}

resource "aws_vpc_endpoint" "dynamodb" {
  tags = {
    Name = "dynamodb"
  }
  service_name      = "com.amazonaws.ap-northeast-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.sample.id
  route_table_ids = flatten([
    aws_route_table.if.id,
    aws_route_table.inner.id,
    values(aws_route_table.forwarder)[*].id
  ])
}

##################################################
# interface endpoint

resource "aws_subnet" "vpce" {
  for_each          = var.network.subnets
  vpc_id            = aws_vpc.sample.id
  cidr_block        = each.value.vpce
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tags = {
    Name = "vpce-${each.key}"
  }
}

resource "aws_security_group" "vpce" {
  name   = "vpce"
  vpc_id = aws_vpc.sample.id
  # vpc全体からの疎通を許可
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "${aws_vpc.sample.cidr_block}",
    ]
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  tags = {
    Name = "ssmmessages"
  }
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-api" {
  tags = {
    Name = "ecr-api"
  }
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  tags = {
    Name = "ecr-dkr"
  }
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "logs" {
  tags = {
    Name = "logs"
  }
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm" {
  tags = {
    Name = "ssm"
  }
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secretsmanager" {
  tags = {
    Name = "secretsmanager"
  }
  service_name        = "com.amazonaws.ap-northeast-1.secretsmanager"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = values(aws_subnet.vpce)[*].id
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.sample.id
  private_dns_enabled = true
}
