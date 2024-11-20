local env = std.native("env");
local env_tag = env("IMAGE_TAG", null);
local tfstate = std.native("tfstate");
local image_tag = if env_tag != null then env_tag else "latest";


{
  containerDefinitions: [
    {
      name: "proxy",
      image: "{{ tfstate `aws_ecr_repository.squid.repository_url` }}:%s" % image_tag,
      cpu: 256,
      memory: 512,
      healthCheck: {
        command: [
          "CMD-SHELL",
          "ps aux | grep '[/]usr/sbin/squid'",
        ],
        interval: 30,
        timeout: 4,
        retries: 1,
        startPeriod: 50,
      },
      portMappings: [
        {
          name: "squid",
          protocol: "tcp",
          hostPort: 8080,
          containerPort: 8080,
        },
      ],
      essential: true,
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          "awslogs-group": tfstate("aws_cloudwatch_log_group.merchant_forwarder.name"),
          "awslogs-region": "{{ must_env `AWS_REGION` }}",
          "awslogs-stream-prefix": image_tag,
        },
      },
    },
  ],
  family: "{{ tfstate `aws_ecs_cluster.gateway.name` }}-proxy",
  taskRoleArn: "{{ tfstate `aws_iam_role.ecs_task_app.arn` }}",
  executionRoleArn: "{{ tfstate `aws_iam_role.ecs_task_execution_default.arn` }}",
  networkMode: "awsvpc",
  volumes: [],
  placementConstraints: [],
  requiresCompatibilities: [
    "FARGATE",
  ],
  cpu: "512",
  memory: "1024",
  runtimePlatform: {
    cpuArchitecture: "ARM64",
    operatingSystemFamily: "LINUX",
  },
}
