resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.inner.id
}

resource "aws_subnet" "app" {
  for_each          = var.network.subnets
  vpc_id            = aws_vpc.sample.id
  cidr_block        = each.value.app
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tags = {
    Name = "app-${each.key}"
  }
}

resource "aws_security_group" "app_api" {
  name   = "app-api"
  vpc_id = aws_vpc.sample.id
  ingress {
    from_port       = 800
    to_port         = 800
    protocol        = "tcp"
    security_groups = [aws_security_group.loadbalancer.id]
    description     = "from alb"
  }
}

resource "aws_security_group" "app_egress" {
  name   = "app-egress"
  vpc_id = aws_vpc.sample.id
}

resource "aws_security_group_rule" "app_vpce" {
  type                     = "egress"
  security_group_id        = aws_security_group.app_egress.id
  description              = "vpce"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpce.id
}

data "aws_ec2_managed_prefix_list" "dynamodb" {
  name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
}

resource "aws_security_group_rule" "app_dynamodb" {
  type              = "egress"
  security_group_id = aws_security_group.app_egress.id
  description       = "dynamodb gateway"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.dynamodb.id]
}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_security_group_rule" "app_s3" {
  type              = "egress"
  security_group_id = aws_security_group.app_egress.id
  description       = "s3 gateway"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.s3.id]
}

resource "aws_security_group_rule" "app_forwarder" {
  type                     = "egress"
  security_group_id        = aws_security_group.app_egress.id
  description              = "forwarder"
  from_port                = 8888
  to_port                  = 8888
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.forwarder.id
}

resource "aws_security_group_rule" "app_postgres" {
  type                     = "egress"
  security_group_id        = aws_security_group.app_egress.id
  description              = "postgres"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.postgresql.id
}

resource "aws_security_group_rule" "app_redis" {
  type                     = "egress"
  security_group_id        = aws_security_group.app_egress.id
  description              = "redis"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redis.id
}
