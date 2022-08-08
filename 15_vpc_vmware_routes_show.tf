##############################################################
# Get all VPC routes to display
##############################################################


data "ibm_is_vpc_routing_table_routes" "routes_default_egress" {
    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = module.vpc-subnets[var.vpc_name].vmware_vpc.default_routing_table

    depends_on  = [
      module.vpc-subnets,
      ibm_is_vpc_routing_table_route.zone_1_nsxt_overlay_routes,
      ibm_is_vpc_routing_table_route.zone_2_nsxt_overlay_routes,
      ibm_is_vpc_routing_table_route.zone_3_nsxt_overlay_routes
    ] 
}

# Create a list of all routes

locals {
  vpc_routes_default_egress = [
    for route in data.ibm_is_vpc_routing_table_routes.routes_default_egress.routes : {
      "name" : route.name,
      "destination" : route.destination,
      "nexthop" : route.nexthop,
      "zone" : route.zone,
    }
  ]
}


# Create a view per zone

locals {
  vpc_egress_routes_per_zone = {
    "${var.ibmcloud_vpc_region}-1" = toset([for each in local.vpc_routes_default_egress : each if each.zone == "${var.ibmcloud_vpc_region}-1"])
    "${var.ibmcloud_vpc_region}-2" = toset([for each in local.vpc_routes_default_egress : each if each.zone == "${var.ibmcloud_vpc_region}-2"])
    "${var.ibmcloud_vpc_region}-3" = toset([for each in local.vpc_routes_default_egress : each if each.zone == "${var.ibmcloud_vpc_region}-3"])
  }
}



data "ibm_is_vpc_routing_table_routes" "routes_tgw_dl_ingress" {
    vpc           = module.vpc-subnets[var.vpc_name].vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table

    depends_on  = [
      module.vpc-subnets,
      ibm_is_vpc_routing_table_route.zone_1_nsxt_overlay_routes,
      ibm_is_vpc_routing_table_route.zone_2_nsxt_overlay_routes,
      ibm_is_vpc_routing_table_route.zone_3_nsxt_overlay_routes
    ] 
}

# Create a list of all routes

locals {
  vpc_routes_tgw_dl_ingress = [
    for route in data.ibm_is_vpc_routing_table_routes.routes_default_egress.routes : {
      "name" : route.name,
      "destination" : route.destination,
      "nexthop" : route.nexthop,
      "zone" : route.zone,
    }
  ]
}

# Create a view per zone


locals {
  vpc_tgw_dl_ingress_routes_per_zone = {
    "${var.ibmcloud_vpc_region}-1" = toset([for each in local.vpc_routes_tgw_dl_ingress : each if each.zone == "${var.ibmcloud_vpc_region}-1"])
    "${var.ibmcloud_vpc_region}-2" = toset([for each in local.vpc_routes_tgw_dl_ingress : each if each.zone == "${var.ibmcloud_vpc_region}-2"])
    "${var.ibmcloud_vpc_region}-3" = toset([for each in local.vpc_routes_tgw_dl_ingress : each if each.zone == "${var.ibmcloud_vpc_region}-3"])
  }
}

