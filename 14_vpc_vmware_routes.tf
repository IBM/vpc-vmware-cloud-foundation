


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
      module.zone_nxt_t_edges
    ] 
}




##############################################################
# Create list of routes to create to NSX-T overlay networks
##############################################################


locals {
  zone_clusters_routes_list = flatten([
    for k, v in var.zone_clusters : [
      for route_v in v.overlay_networks :  {
        name = "${v.name}-${route_v.name}"
        destination = route_v.destination
        cluster_name = v.name
      }
    ] if v.nsx_t_edges == true
  ])
  zone_clusters_routes_map = {
    for v in local.zone_clusters_routes_list : v.name => {
      name = v.name
      destination = v.destination
      cluster_key = v.cluster_name
    } 
  }
}


##############################################################
# Create VPC egress routes to NSX-T overlay networks
##############################################################


resource "ibm_is_vpc_routing_table_route" "zone_1_nsxt_overlay_routes" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-1"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edges
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_2_nsxt_overlay_routes" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-2"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-2"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edges
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_3_nsxt_overlay_routes" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-3"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table
    zone          = "${var.ibmcloud_vpc_region}-3"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      module.zone_nxt_t_edges
    ] 
}



##############################################################
# Create VPC ingress routes to NSX-T overlay networks
##############################################################

# Note...VPC routes outside VPC prefix are not advertised to TGW or Direct Link  
# this is a workaround before the capability is available.

resource "ibm_is_vpc_address_prefix" "nsx_t_overlay_prefix" {
    for_each    = local.zone_clusters_routes_map
    name = "prefix-nsx-t-${each.value.name}-${var.vpc_zone}"

    vpc  = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    zone = var.vpc_zone # prefix is created only on the zone where VMware is deployed

    cidr = each.value.destination

    depends_on  = [
      module.vpc-subnets,
    ] 
}


resource "ibm_is_vpc_routing_table_route" "zone_1_nsxt_overlay_routes_ingress" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-1"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-1"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress,
      module.zone_nxt_t_edges
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_2_nsxt_overlay_routes_ingress" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-2"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-2"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress,
      module.zone_nxt_t_edges
    ] 
}

resource "ibm_is_vpc_routing_table_route" "zone_3_nsxt_overlay_routes_ingress" {
    for_each      = local.zone_clusters_routes_map

    name          = "nsx-t-${each.value.name}-${var.ibmcloud_vpc_region}-3"

    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table
    zone          = "${var.ibmcloud_vpc_region}-3"

    destination   = each.value.destination
    action        = "deliver"
    next_hop      = local.zone_clusters_nsx_t_t0_values[each.value.cluster_key].ha-vip.private_uplink.ip_address

    depends_on  = [
      module.vpc-subnets,
      ibm_is_vpc_address_prefix.nsx_t_overlay_prefix,
      ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress,
      module.zone_nxt_t_edges
    ] 
}



