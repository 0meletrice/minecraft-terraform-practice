# vpc作成
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minecraft"
  }
}

# サブネット作成
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "minecraft"
  }
}

# クラスター名
resource "aws_ecs_cluster" "main" {
  name = "minecraft"
}

# タスク定義
resource "aws_ecs_task_definition" "task" {
  family                   = "minecraft"
  cpu                      = "2048"
  memory                   = "8192"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
  execution_role_arn = aws_iam_role.log_for_minecraft.arn
}

# ECSサービス
resource "aws_ecs_service" "minecraft" {
  name                              = "minecraft"
  cluster                           = aws_ecs_cluster.main.arn
  task_definition                   = aws_ecs_task_definition.task.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"

  #ネット設定
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.allow_tls.id]
    subnets = [aws_subnet.main.id]
  }
}

# セキュリティグループ定義
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 25565
    to_port          = 25565
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

# ルートテーブル
resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

# ロググループ
resource "aws_cloudwatch_log_group" "minecraft" {
  name              = "/ecs/minecraft"
  retention_in_days = 30
}

# ログ出力用ロール
resource "aws_iam_role" "log_for_minecraft" {
  name = "log_for_minecraft"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid" = "",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
}


