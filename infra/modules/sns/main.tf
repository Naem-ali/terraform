resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.env}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "topic_arn" {
  value = aws_sns_topic.alerts.arn
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "alert_email" {
  type = string
}
