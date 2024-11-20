# ecspresso skeleton

アプリケーションコンテナのサービス/タスク定義のskeleton。
（実プロダクトでは環境変数の共有メリットなどからアプリリポジトリ内での管理をおすすめします）

例として、APIサービスとそのPROXYサービスの定義を用意。
両者はServiceConnectで接続。

# 準備

- `ecspresso`, `ecschedule` パスが通るようにインストール
  - `jsonnet` もあるとdebugしやすい
- 認証情報: awscliのprofileとして `staging` `production` を準備
- s3にtfstateを配置
  - このskeletonはパスが環境毎の前提: `s3://bucket/path/staging/terraform.tfstate`

## 使い方

ecspresso deploy
```
# render
$AWS_REGION=ap-northeast-1 CLUSTER= SERVICE=api AWS_PROFILE=staging \
WORKSPACE=staging S3_PATH_BASE=bucket/path \
ecspresso render taskdef --config="./ecspresso.yaml" \
--envfile="vars/all.env" \
--envfile="vars/staging.env" \
--ext-str IMAGE_TAG=latest

$AWS_REGION=ap-northeast-1 CLUSTER= SERVICE=api AWS_PROFILE=staging \
WORKSPACE=staging S3_PATH_BASE=bucket/path \
ecspresso deploy --config="./ecspresso.yaml" \
--envfile="vars/all.env" \
--envfile="vars/staging.env" \
--ext-str IMAGE_TAG=latest
```

ecschedule 
```
$AWS_REGION=ap-northeast-1 CLUSTER= AWS_PROFILE=staging \
WORKSPACE=staging S3_PATH_BASE=bucket/path \
ecschedule diff --all --conf ecschedule.jsonnet

$AWS_REGION=ap-northeast-1 CLUSTER= AWS_PROFILE=staging \
WORKSPACE=staging S3_PATH_BASE=bucket/path \
ecschedule apply --all --conf ecschedule.jsonnet
```

## ECS exec

サイドカーやServiceConnectのenvoyにも入れる

- servicedef `enableExecuteCommand: true` にして不要なキーを削除
  - debug目的で入るなら `healthCheckGracePeriodSeconds` や `loadBalancers` はキーごと削除 
- taskdef の `taskRoleArn`に `aws_iam_role_policy_attachment.ecs_exec` されたロールがついてるか確認 & 不要なキーを削除(各コメントアウト参照)
  - healthCehck.commandなどは確定で成功させると良い cf, envs.libsonnet containerDefinitionsMackerel

```
$aws ecs execute-command --region ap-northeast-1 --cluster $cluster --task arn:aws:ecs:ap-northeast-1:id:task/b/xxx --interactive --command "/bin/sh" --container api
```

上で入れない場合、大体internal errorとメッセージから原因を判断できないため、以下で確認

- 必ず読んで確認： https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/ecs-exec.html
  - 特に考慮事項のところを読み飛ばさず確認すること
- 非公式のおすすめ資料
  - https://zenn.dev/fujiwara/scraps/eea64fd3215e95
  - https://tech.uzabase.com/entry/2024/03/27/181153
- checkerで確認: https://github.com/aws-containers/amazon-ecs-exec-checker.git
  - 内部で `describe-tasks` してるが結果の一番目しか見ない。複数ある場合は `check-ecs-exec.sh` を改造
- 特にハマるポイント
  - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` がtask envに設定されているとダメ
  - `HTTP_PROXY` / `HTTPS_PROXY` がtask envに設定されているとダメ

```
$aws ecs describe-tasks --region ap-northeast-1 --cluster $cluster --task $arn

# この結果のtasks[].attachments[] が複数あると現状エラーとなる(ServiceConnectがある時など)
# https://github.com/aws-containers/amazon-ecs-exec-checker/pull/73/files がマージされるまでは同様に修正ください
 
$AWS_REGION=ap-northeast-1 ./check-ecs-exec.sh $cluster $task_arn
```

それでもexecできない時は以下のワークアラウンドもある。
targetの命名が難しい、$runtimeId はdescribe-tasksで取得する。

```
$aws ssm start-session --target ecs:$cluster_$taskId_$runtimeId --document-name AWS-StartInteractiveCommand --parameters '{"command":["/bin/bash"]}'
```