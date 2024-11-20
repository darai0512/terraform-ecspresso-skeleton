local tfstate = std.native("tfstate");
local must_env = std.native("must_env");
local target_cluster = must_env("CLUSTER");
local secretsmanager_arn = tfstate('module.app["%s"].aws_secretsmanager_secret.app.arn' % target_cluster);
local asm(key) = { name: key, valueFrom: "%s:%s::" % [secretsmanager_arn, key] };

{
  environment: [
    { name: "ECS_CONTAINER_STOP_TIMEOUT", value: "2" },
    { name: "APP_ENVIRONMENT_ROOT_DOMAIN", value: tfstate('module.app["%s"].aws_route53_zone.app.name' % target_cluster) },
    # { name: "REDIS_HOST", value: "{{ tfstate `aws_elasticache_replication_group.cache.primary_endpoint_address` }}" },
    # { name: "BROKER_URL", value: "redis://{{ tfstate `aws_elasticache_replication_group.celery.primary_endpoint_address` }}:6379/0" },
    { name: "SQLALCHEMY_LOGLEVEL", value: "{{ env `SQLALCHEMY_LOGLEVEL` `` }}" },
  ],
  secrets: [
    asm("AWS_ACCESS_KEY_ID_EXTERNAL"),
    asm("AWS_SECRET_ACCESS_KEY_EXTERNAL"),
  ],
  "containerDefinitionsMackerel": [
    {
      "name": "mackerel-container-agent",
      "image": "mackerel/mackerel-container-agent:latest",
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "true"
        ],
        "interval": 30,
        "timeout": 10,
        "retries": 1,
        "startPeriod": 50
      },
      "environment": [
        {
          "name": "AWS_REGION",
          "value": "{{ must_env `AWS_REGION` }}"
        },
        {
          "name": "TZ",
          "value": "Asia/Tokyo"
        },
        {
          "name": "MACKEREL_CONTAINER_PLATFORM",
          "value": "ecs"
        },
        { name: "HTTP_PROXY", value: "http://forwarder:8080" },
        { name: "HTTPS_PROXY", value: "http://forwarder:8080" },
      ],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "{{ tfstate `aws_cloudwatch_log_group.mackerel.name` }}",
          "awslogs-region": "{{ must_env `AWS_REGION` }}",
          "awslogs-stream-prefix": "mackerel"
        }
      },
      "secrets": [
        asm("MACKEREL_APIKEY")
      ]
    }
  ]
}
