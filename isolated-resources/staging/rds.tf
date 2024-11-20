resource "aws_iam_role" "proxy_main" {
  name = "sample-rds-proxy-main"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "rds.amazonaws.com"
        },
        "Action" : "sts:AssumeRole",
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "rds_auth_app" {
  name                    = "rds/main/sample_app"
  recovery_window_in_days = 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.proxy_main.arn
        },
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : "*",
      }
    ]
  })
}

resource "aws_db_proxy" "main" {
  name = "main"

  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 3600 # 60 min
  require_tls            = false
  role_arn               = aws_iam_role.proxy_main.arn
  vpc_security_group_ids = local.rds.security_group_ids
  vpc_subnet_ids         = local.rds.subnet_ids

  auth {
    auth_scheme               = "SECRETS"
    client_password_auth_type = "POSTGRES_MD5"
    iam_auth                  = "DISABLED"
    secret_arn                = aws_secretsmanager_secret.rds_auth_app.arn
  }
  # auth {} # 複数記述可能
}

resource "aws_db_proxy_default_target_group" "main_default" {
  db_proxy_name = aws_db_proxy.main.name
  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  db_cluster_identifier = aws_rds_cluster.main.id
  db_proxy_name         = aws_db_proxy.main.name
  target_group_name     = aws_db_proxy_default_target_group.main_default.name
}

resource "aws_db_subnet_group" "db" {
  name       = "staging"
  subnet_ids = local.rds.subnet_ids
}

resource "aws_rds_cluster" "main" {
  # https://github.com/hashicorp/terraform-provider-aws/issues/30596
  # allocated_storageとdb_cluster_instance_classを指定するとaws_rds_cluster_instanceが作成されない
  cluster_identifier     = "main"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "14.9"
  database_name          = "sample"
  master_username        = "sample"
  master_password        = "sample"
  port                   = 5432
  deletion_protection    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = local.rds.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.db.name
  serverlessv2_scaling_configuration {
    max_capacity = 2
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "main" {
  identifier                 = "main"
  cluster_identifier         = aws_rds_cluster.main.id
  instance_class             = "db.serverless"
  engine                     = aws_rds_cluster.main.engine
  engine_version             = aws_rds_cluster.main.engine_version
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  db_subnet_group_name       = aws_rds_cluster.main.db_subnet_group_name
}
