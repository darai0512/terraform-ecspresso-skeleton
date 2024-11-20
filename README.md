# terraform-skeleton

ref: https://registry.terraform.io/providers/hashicorp/aws/latest
ecspresso-skeleton is [here](./ecspresso/README.md)

# setup

1. install terraform

https://developer.hashicorp.com/terraform/install?product_intent=terraform


2. aws account

awscliのprofileとして`production` `staging`とマルチアカウントがある想定。
（シングルアカウントでも使えます。`default`など命名は変えても大丈夫ですがリソース名に使われます）

ファイル内容
```
$cat ~/.aws/credentials
[staging]
aws_access_key_id = xxx
aws_secret_access_key = yyy
[production]
aws_access_key_id = xxx
aws_secret_access_key = yyy

$cat ~/.aws/config
[staging]
region = ap-northeast-1
[production]
region = ap-northeast-1
```

cloudfrontなどは`region=us-east-1`(=global)になる。
関連エラーがでたら環境変数`AWS_DEFAULT_REGION`などで微調整ください。

3. init

```
$ terraform init
```

4. switch workspace

workespaceの切り替えは、以下のコマンドを実行します。
```
$ terraform workspace select staging
$ terraform workspace show
```
workespaceの一覧を取得する場合は、以下のコマンドを実行します。
```
$ terraform workspace list
```

もし、worekspeaceがない場合は、以下のコマンドを実行します。
```
$ terraform workspace new staging
```

# exec

```
$ terraform plan -var-file=variables-$(terraform workspace show).tfvars
# or ラッパー
$ ./tf plan
```

# 環境設定

現在選択されているworkspaceに沿って `(WORKSPACE_NAME).tfvars` が自動的に読み込まれます。


# その他

## 用語

+ アカウント
    + awsアカウントの別
    + 当skeletonではstagingアカウント・productionアカウントという想定
+ 環境
    + アプリケーションの別
    + staging1、staging2...

## ネーミングポリシーなど

+ 特に言及のないものは小文字ケバブケース
    + 各サービスの慣例があるならそれを優先してよい
+ 短く保つ(重複可能性には気を配る)
+ 名前空間を意識する
    + s3はグローバルで一意、アカウント内で一意、環境ごとに一意、...
+ ユニークにするための前置・後置
    + ex, 環境名をつけるときは前置する
        + アカウントのGUIで一覧したときに環境ごとのリソースが固まって並ぶことを期待
    + アカウント名をつけるときは後置する
+ iam-role
    + 小文字
    + kebab-case
+ IAMPolicy
    + prefixを用意
    + CamelCase
    + AWSサービス名などに出てくるアクロニムはそのまま