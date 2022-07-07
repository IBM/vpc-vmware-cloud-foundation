
##############################################################
# Create VPC ingress routing table to NSX-T overlay networks
##############################################################


resource "ibm_is_vpc_routing_table" "nsxt_overlay_route_table_ingress" {
    name                          = "${local.resources_prefix}-nsx-t-ingress-routing-table"
    vpc                           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    route_direct_link_ingress     = true
    route_transit_gateway_ingress = true
    route_vpc_zone_ingress        = true

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ] 
}


##############################################################
# Create VPC egress routes to NSX-T overlay networks
##############################################################


resource "ibm_is_vpc_routing_table_route" "zone_1_nsxt_overlay_routes" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-1"

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_2_nsxt_overlay_routes" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-2"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-2"

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_3_nsxt_overlay_routes" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-3"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-3"

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
    ] 
}




##############################################################
# Create VPC ingress routes to NSX-T overlay networks
##############################################################


# Note...VPC routes outside VPC prefix are not advertised to TGW or Direct Link  
# this is a workaround before the capability is available.

resource "ibm_is_vpc_address_prefix" "nsx_t_overlay_prefix" {
    for_each    = toset(var.nsx_t_overlay_networks)
    name = "prefix-nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.vpc_zone}"

    vpc  = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    zone = var.vpc_zone

    cidr = each.key

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ] 
}


resource "ibm_is_vpc_routing_table_route" "zone_1_nsxt_overlay_routes_ingress" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-1"
    #zone          = var.vpc_zone

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_2_nsxt_overlay_routes_ingress" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-2"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-2"

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_3_nsxt_overlay_routes_ingress" {
    for_each      = toset(var.nsx_t_overlay_networks)

    name          = "nsx-t-${replace(replace(each.key, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-3"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-3"

    destination   = each.key
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress
    ] 
}



##############################################################
# Create VPC egress routes to VCF AVN networks
##############################################################


resource "ibm_is_vpc_routing_table_route" "zone_vcf_avn_local_network" {
    count       = var.enable_vcf_mode ? 3 : 0

    name          = "vcf-avn-local-network-${var.ibmcloud_vpc_region}-${count.index + 1}"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-${count.index + 1}"

    destination   = var.vcf_avn_local_network_prefix
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ]
}


resource "ibm_is_vpc_routing_table_route" "zone_vcf_avn_x_region_network" {
    count       = var.enable_vcf_mode ? 3 : 0

    name          = "vcf-avn-x-region-network-${var.ibmcloud_vpc_region}-${count.index + 1}"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-${count.index + 1}"

    destination   = var.vcf_avn_x_region_network_prefix
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ]
}


##############################################################
# Create VPC ingress routes to VCF AVN networks
##############################################################


# Note...VPC routes outside VPC prefix are not advertised to TGW or Direct Link  
# this is a workaround before the capability is available.

resource "ibm_is_vpc_address_prefix" "zone_vcf_avn_local_network_prefix" {
    count       = var.enable_vcf_mode ? 1 : 0  
    name        = "prefix-nsx-t-${replace(replace(var.vcf_avn_local_network_prefix, ".", "-"), "/", "-")}-${var.vpc_zone}"

    vpc         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    zone        = var.vpc_zone

    cidr        = var.vcf_avn_local_network_prefix

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_vcf_avn_local_network_ingress" {
    count       = var.enable_vcf_mode ? 3 : 0  

    name          = "nsx-t-${replace(replace(var.vcf_avn_local_network_prefix, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone        = "${var.ibmcloud_vpc_region}-${count.index + 1}" 

    destination   = var.vcf_avn_local_network_prefix
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
      ibm_is_vpc_address_prefix.zone_vcf_avn_local_network_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress
    ] 
}


# Note...VPC routes outside VPC prefix are not advertised to TGW or Direct Link  
# this is a workaround before the capability is available.

resource "ibm_is_vpc_address_prefix" "zone_vcf_avn_x_region_network_prefix" {
    count       = var.enable_vcf_mode ? 1 : 0  
    name        = "prefix-nsx-t-${replace(replace(var.vcf_avn_x_region_network_prefix, ".", "-"), "/", "-")}-${var.vpc_zone}"

    vpc         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    zone        = var.vpc_zone

    cidr        = var.vcf_avn_x_region_network_prefix

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_vcf_avn_x_region_network_ingress" {
    count       = var.enable_vcf_mode ? 3 : 0  

    name          = "nsx-t-${replace(replace(var.vcf_avn_x_region_network_prefix, ".", "-"), "/", "-")}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone        = "${var.ibmcloud_vpc_region}-${count.index + 1}" 

    destination   = var.vcf_avn_x_region_network_prefix
    action        = "deliver"
    next_hop      = local.nsx_t_t0.ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edge,
      ibm_is_vpc_address_prefix.zone_vcf_avn_x_region_network_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress
    ] 
}


