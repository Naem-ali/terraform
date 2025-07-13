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
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ELB", "HTTPCode_Backend_5XX", "LoadBalancer", "*"],
            [".", "RequestCount"],
            [".", "Latency"]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "Load Balancer Metrics"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["CWAgent", "mem_used_percent", "InstanceId", "*"],
            [".", "disk_used_percent"],
            [".", "swap_used_percent"]
          ]
          period = 300
          region = data.aws_region.current.name
          title  = "System Metrics"
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

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-memory-high-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "mem_used_percent"
  namespace          = "CWAgent"
  period             = 300
  statistic          = "Average"
  threshold          = var.memory_threshold
  alarm_description  = "Memory utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-disk-high-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "disk_used_percent"
  namespace          = "CWAgent"
  period             = 300
  statistic          = "Average"
  threshold          = var.disk_threshold
  alarm_description  = "Disk utilization is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_ids[count.index]
  }
}

resource "aws_cloudwatch_metric_alarm" "network_anomaly" {
  count               = length(var.instance_ids)
  alarm_name          = "${var.project}-${var.env}-network-anomaly-${var.instance_ids[count.index]}"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "ad1"
  alarm_description   = "Network traffic anomaly detected"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  metric_query {
    id          = "ad1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "NetworkOut (Expected)"
    return_data = true
  }

  metric_query {
    id = "m1"
    metric {
      metric_name = "NetworkOut"
      namespace   = "AWS/EC2"
      period     = 300
      stat       = "Average"
      dimensions = {
        InstanceId = var.instance_ids[count.index]
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.project}-${var.env}-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name        = "HTTPCode_Target_5XX_Count"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Sum"
  threshold          = var.error_rate_threshold
  alarm_description  = "High error rate detected"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "*"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${var.project}-${var.env}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name        = "TargetResponseTime"
  namespace          = "AWS/ApplicationELB"
  period             = 300
  statistic          = "Average"
  threshold          = 1  # 1 second
  alarm_description  = "API latency is too high"
  alarm_actions      = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "*"
  }
}

data "aws_region" "current" {}
