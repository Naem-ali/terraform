resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-${var.env}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "*"],
            [".", "NetworkIn"],
            [".", "NetworkOut"]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "EC2 Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/NetworkFirewall", "DroppedPackets", "FirewallName", "${var.project}-${var.env}-firewall"]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "Firewall Dropped Packets"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-cpu-high-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = 80
  alarm_description  = "CPU utilization is too high"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "firewall_drops" {
  alarm_name          = "${var.project}-${var.env}-firewall-drops"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name        = "DroppedPackets"
  namespace          = "AWS/NetworkFirewall"
  period             = 300
  statistic          = "Sum"
  threshold          = 1000
  alarm_description  = "High number of dropped packets by firewall"
  alarm_actions     = [aws_sns_topic.alerts.arn]

  dimensions = {
    FirewallName = "${var.project}-${var.env}-firewall"
  }
}

data "aws_region" "current" {}
