resource "aws_cloudwatch_metric_alarm" "system_status" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-system-check-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.unhealthy_threshold
  metric_name        = "StatusCheckFailed_System"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Maximum"
  threshold          = 0
  alarm_description  = "EC2 system status check failed"
  alarm_actions     = [
    "arn:aws:automate:${data.aws_region.current.name}:ec2:recover",
    aws_sns_topic.auto_healing.arn
  ]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_status" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-instance-check-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.unhealthy_threshold
  metric_name        = "StatusCheckFailed_Instance"
  namespace          = "AWS/EC2"
  period             = 60
  statistic          = "Maximum"
  threshold          = 0
  alarm_description  = "EC2 instance status check failed"
  alarm_actions     = [
    aws_sns_topic.auto_healing.arn
  ]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "target_health" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-target-health-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.unhealthy_threshold
  metric_name        = "UnHealthyHostCount"
  namespace          = "AWS/ApplicationELB"
  period             = 60
  statistic          = "Maximum"
  threshold          = 0
  alarm_description  = "Target health check failed"
  alarm_actions     = [
    aws_sns_topic.auto_healing.arn
  ]

  dimensions = {
    TargetGroup = var.target_group_arn
  }
}

resource "aws_cloudwatch_composite_alarm" "overall_health" {
  count              = length(var.instance_ids)
  alarm_name         = "${var.project}-${var.env}-overall-health-${var.instance_ids[count.index]}"
  alarm_description  = "Composite alarm for overall instance health"
  alarm_actions     = [aws_sns_topic.auto_healing.arn]

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.system_status[count.index].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.instance_status[count.index].alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.target_health[count.index].alarm_name})"
}

resource "aws_sns_topic" "auto_healing" {
  name = "${var.project}-${var.env}-auto-healing"
}

resource "aws_sns_topic_subscription" "auto_healing_email" {
  topic_arn = aws_sns_topic.auto_healing.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_lambda_function" "health_check" {
  filename      = "${path.module}/lambda/health_check.zip"
  function_name = "${var.project}-${var.env}-health-check"
  role         = aws_iam_role.lambda_health_check.arn
  handler      = "index.handler"
  runtime      = "nodejs16.x"
  timeout      = 30

  environment {
    variables = {
      INSTANCE_IDS     = jsonencode(var.instance_ids)
      TARGET_GROUP_ARN = var.target_group_arn
      SNS_TOPIC_ARN   = aws_sns_topic.auto_healing.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "health_check" {
  name                = "${var.project}-${var.env}-health-check"
  description         = "Trigger health check Lambda function"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "health_check" {
  rule      = aws_cloudwatch_event_rule.health_check.name
  target_id = "HealthCheck"
  arn       = aws_lambda_function.health_check.arn
}

resource "aws_iam_role" "lambda_health_check" {
  name = "${var.project}-${var.env}-lambda-health-check"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_health_check" {
  name = "${var.project}-${var.env}-lambda-health-check"
  role = aws_iam_role.lambda_health_check.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "elasticloadbalancing:DescribeTargetHealth",
          "sns:Publish"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_region" "current" {}
