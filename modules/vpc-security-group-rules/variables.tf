
variable "resource_group_id" {
  description = "Resource group ID"
  type        = string
  default     = null
}

variable "security_group" {
  description = "Existing Security Group's ID to which rules are to be attached."
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "Security Group rules"
  type = list(object({
    name       = string
    direction  = string
    remote     = string
    remote_id  = string
    ip_version = string
    icmp = object({
#      code = number
      type = number
    })
    tcp = object({
      port_max = number
      port_min = number
    })
    udp = object({
      port_max = number
      port_min = number
    })
  }))
  default = []
}