resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project}-${var.env}-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_filtering.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.suricata_rules.arn
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-firewall-policy"
    Environment = var.env
  }
}

resource "aws_networkfirewall_rule_group" "domain_filtering" {
  capacity = 100
  name     = "${var.project}-${var.env}-domain-filtering"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["10.0.0.0/8"]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types        = ["HTTP_HOST", "TLS_SNI"]
        targets             = var.blocked_domains
      }
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-domain-filtering"
    Environment = var.env
  }
}

resource "aws_networkfirewall_rule_group" "suricata_rules" {
  capacity = 100
  name     = "${var.project}-${var.env}-suricata"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = <<EOT
# Block SQL injection attempts
alert tcp any any -> $HOME_NET any (msg:"SQL Injection Attempt"; flow:to_server,established; content:"UNION"; nocase; pcre:"/UNION.*SELECT/i"; sid:1000001; rev:1;)
# Block XSS attempts
alert tcp any any -> $HOME_NET any (msg:"XSS Attempt"; flow:to_server,established; content:"<script>"; nocase; sid:1000002; rev:1;)
EOT
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-suricata"
    Environment = var.env
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project}-${var.env}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id             = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_cidrs
    content {
      subnet_id = aws_subnet.firewall[subnet_mapping.key].id
    }
  }

  tags = {
    Name        = "${var.project}-${var.env}-firewall"
    Environment = var.env
  }
}

resource "aws_subnet" "firewall" {
  count             = length(var.firewall_subnet_cidrs)
  vpc_id            = var.vpc_id
  cidr_block        = var.firewall_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project}-${var.env}-firewall-${count.index + 1}"
    Environment = var.env
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
