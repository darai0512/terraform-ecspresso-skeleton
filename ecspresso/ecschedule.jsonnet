local must_env = std.native("must_env");

local rule(schedule, command, name="") =
  local rule_name = std.strReplace(if name != "" then name else command[1], "/", "_");
  {
    name: rule_name,
    scheduleExpression: schedule,
    taskDefinition: "{{ must_env `CLUSTER` }}-api",
    containerOverrides: [
      {
        name: rule_name,
        command: ["run"] + command,
        // todo log groupを変えたい. logConfiguration: {} を書いてもダメそう
      },
    ],
  };

{
  region: "{{ must_env `AWS_REGION` }}",
  cluster: "{{ must_env `CLUSTER` }}",
  rules: [
    rule("cron(0 16 15,28-31 * ? *)", ["cmd", "a.py"], "task-name"),
    rule("cron(*/20 * * * ? *)", ["cmd", "b.py"]),
  ],
  plugins: [
    {
      name: "tfstate",
      config: {
        url: "s3://{{ must_env `S3_PATH_BASE` }}/{{ must_env `AWS_PROFILE` }}/terraform.tfstate",
      },
    },
  ],
}
