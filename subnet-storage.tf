##############################################################
# 共用ストレージを配置するsubnet
##############################################################

##################################################
# subnet

resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.inner.id
}

resource "aws_subnet" "db" {
  for_each          = var.network.subnets
  vpc_id            = aws_vpc.sample.id
  cidr_block        = each.value.db
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tags = {
    Name = "db-${each.key}"
  }
}

##################################################
# cache subnet group

resource "aws_elasticache_subnet_group" "app" {
  name       = "storage-subnet"
  subnet_ids = values(aws_subnet.db)[*].id
}

# rds subnet groupはisolated-resourcesで管理

##################################################
# security group

# app -> redis
resource "aws_security_group" "redis" {
  name   = "redis"
  vpc_id = aws_vpc.sample.id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app_egress.id]
  }
}

# app -> postgresql
resource "aws_security_group" "postgresql" {
  name        = "postgresql"
  description = "postgresql security group"
  vpc_id      = aws_vpc.sample.id
  ingress = [{
    cidr_blocks     = []
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app_egress.id]
    # rds proxyとrdsそれぞれにこのsgを付けて、proxy->rds間の通信を許可
    self             = true
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
  }]

  egress = [{
    cidr_blocks      = []
    protocol         = "tcp"
    from_port        = 5432
    to_port          = 5432
    security_groups  = []
    self             = true
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
  }]
}
