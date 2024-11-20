local envs = import "envs.libsonnet";
local tfstate = std.native("tfstate");
local env = std.native("env");
local must_env = std.native("must_env");
local target_cluster = must_env("CLUSTER");
local api_port = tfstate('module.app["%s"].aws_lb_target_group.api.port' % target_cluster);
local env_tag = env("IMAGE_TAG", null);
local image_tag = if env_tag != null then env_tag else target_cluster;


{
  containerDefinitions: [
    {
      name: "api",
      image: "{{ tfstate `aws_ecr_repository.app_testing.repository_url` }}:%s" % image_tag,
      cpu: 256,
      memory: 512,
      # entryPoint: [ # override if enableExecuteCommand=true
      #   "/bin/bash",
      #   "-c",
      #   "sleep infinity"
      # ],
      command: [], # delete key if enableExecuteCommand=true
      portMappings: [
        {
          name: "api",
          protocol: "tcp",
          appProtocol: "http",
          containerPort: api_port,
        },
      ],
      essential: true,
      environment: envs.environment + [
        { name: "APP_TYPE", value: "api" },
      ],
      secrets: envs.secrets,
      mountPoints: [],
      volumesFrom: [],
      logConfiguration: {
        logDriver: "awslogs",
        options: {
          "awslogs-group": tfstate('module.app["%s"].aws_cloudwatch_log_group.api.name' % target_cluster),
          "awslogs-region": "{{ must_env `AWS_REGION` }}",
          "awslogs-stream-prefix": image_tag,
        },
      },
    },
  ] + envs.containerDefinitionsMackerel,
  family: "%s-api" % target_cluster,
  taskRoleArn: "{{ tfstate `aws_iam_role.app_task.arn` }}",
  executionRoleArn: "{{ tfstate `aws_iam_role.app_task_execution.arn` }}",
  networkMode: "awsvpc",
  volumes: [],
  placementConstraints: [],
  requiresCompatibilities: [
    "FARGATE",
  ],
  #  linuxParameters: { # set if enableExecuteCommand=true
  #    initProcessEnabled: true
  #  },
  cpu: "512",
  memory: "1024",
  runtimePlatform: {
    cpuArchitecture: "ARM64",
    operatingSystemFamily: "LINUX",
  },
}
