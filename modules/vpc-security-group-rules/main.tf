#---------------------------------------------------------
# Create security group rules resources
#---------------------------------------------------------

resource "ibm_is_security_group_rule" "sg_rules" {
  for_each   = { for r in var.security_group_rules : r.name => r }
  group      = var.security_group
  direction  = each.value.direction
#  remote     = each.value.remote != "" ? each.value.remote : null
  remote = each.value.remote_id == null ? each.value.remote : each.value.remote_id
  ip_version = each.value.ip_version != "" ? each.value.ip_version : "ipv4"
  dynamic "icmp" {
    for_each = lookup(each.value, "icmp") == null ? [] : [each.value.icmp]
    content {
      code = lookup(icmp.value, "code", null)
      type = lookup(icmp.value, "type", null)
    }
  }
  dynamic "tcp" {
    for_each = lookup(each.value, "tcp") == null ? [] : [each.value.tcp]
    content {
      port_min = lookup(tcp.value, "port_min", 1)
      port_max = lookup(tcp.value, "port_max", 65535)
    }
  }
  dynamic "udp" {
    for_each = lookup(each.value, "udp") == null ? [] : [each.value.udp]
    content {
      port_min = lookup(udp.value, "port_min", 1)
      port_max = lookup(udp.value, "port_max", 65535)
    }
  }
}

output "security_group_rules" {
  description = "All the Security group Rules"
  value       = [for rule in ibm_is_security_group_rule.sg_rules : rule.id]
}

