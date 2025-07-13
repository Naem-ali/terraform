output "firewall_endpoints" {
  description = "Map of AZ to firewall endpoint"
  value       = { for az, ep in aws_networkfirewall_firewall.main.firewall_status[0].sync_states : ep.availability_zone => ep.attachment[0].endpoint_id }
}

output "firewall_subnet_ids" {
  description = "List of firewall subnet IDs"
  value       = aws_subnet.firewall[*].id
}
