##############################################################
# Get all VPC routes to display
##############################################################


data "ibm_is_vpc_routing_table_routes" "routes_default_egress" {
    vpc           = ibm_is_vpc.vmware_vpc.id
    routing_table =  ibm_is_vpc.vmware_vpc.default_routing_table

    depends_on  = [
      module.vpc_subnets,
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
    vpc           = ibm_is_vpc.vmware_vpc.id
    routing_table = ibm_is_vpc_routing_table.nsxt_overlay_route_table_ingress.routing_table

    depends_on  = [
      module.vpc_subnets,
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


##############################################################
# Show example routes to be created in NSX-T T0
##############################################################



locals {
  nsx_t_t0_routes_to_be_created_per_cluster_domain = { 
    for k, v in var.zone_clusters : v.name => {
      public = [ for pubroute_k in var.customer_public_routes : 
        {
          "name" : "private-${replace(replace(pubroute_k, ".", "-"),"/","-")}",
          "destination" : pubroute_k,
          "nexthop" : v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].default_gateway : local.subnets_map.edges["wl-t0-pub"].default_gateway,
          "t0_cluster" : v.name,
          "domain" : v.domain
        }
      ],
      private = [ for privroute_k in var.customer_private_routes : 
        {
          "name" : "private-${replace(replace(privroute_k, ".", "-"),"/","-")}",
          "destination" : privroute_k,
          "nexthop" : v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].default_gateway : local.subnets_map.edges["wl-t0-priv"].default_gateway,
          "t0_cluster" : v.name,
          "domain" : v.domain
        }
      ]
    } if v.nsx_t_edges == true
  }
}


