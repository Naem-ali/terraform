resource "aws_budgets_budget" "cost" {
  name              = "${var.project}-${var.env}-budget"
  budget_type       = "COST"
  limit_amount      = var.monthly_budget
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
  }
}

resource "aws_scheduler_schedule" "dev_shutdown" {
  count = var.env == "dev" ? 1 : 0
  name = "dev-environment-shutdown"

  schedule_expression = "cron(0 18 ? * MON-FRI *)"  # 6 PM weekdays
  target {
    arn = aws_lambda_function.stop_resources.arn
  }
}
