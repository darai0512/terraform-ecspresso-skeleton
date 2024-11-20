############################################
# 外部と直接通信するsubnet
############################################

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.sample.id
}

############################################
# subnet

resource "aws_route_table" "if" {
  vpc_id = aws_vpc.sample.id
  route {
    cidr_block = var.network.vpc_cidr_block
    gateway_id = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

}

resource "aws_route_table_association" "if" {
  for_each       = aws_subnet.if
  subnet_id      = each.value.id
  route_table_id = aws_route_table.if.id
}

resource "aws_subnet" "if" {
  for_each          = var.network.subnets
  vpc_id            = aws_vpc.sample.id
  cidr_block        = each.value.if
  availability_zone = "${data.aws_region.current.name}${each.key}"
  tags = {
    Name = "if-${each.key}"
  }
}

############################################
# security group

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "loadbalancer" {
  name   = "loadbalancer"
  vpc_id = aws_vpc.sample.id
  # cloudfront -> alb
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = ["${data.aws_ec2_managed_prefix_list.cloudfront.id}"]
  }
}

# alb -> app
resource "aws_security_group_rule" "loadbalancer_egress" {
  type                     = "egress"
  from_port                = 800
  to_port                  = 80
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_egress.id

  security_group_id = aws_security_group.loadbalancer.id
}
