{
  "skipEsxThumbprintValidation": true,
  "managementPoolName": "${vcf_mgmt_domain}-np01",
  "sddcManagerSpec": {
    "secondUserCredentials": {
      "username": "vcf",
      "password": "${vcf_password}"
    },
    "ipAddress": "${sddc_manager_ip}",
    "netmask": "${sddc_manager_mask}",
    "hostname": "sddc-manager",
    "licenseKey": "${sddc_manager_license}",
    "rootUserCredentials": {
      "username": "root",
      "password": "${vcf_password}"
    },
    "localUserPassword": "${vcf_password}",
    "vcenterId": "vcenter-1"
  },
  "sddcId": "${vcf_mgmt_domain}",
  "esxLicense": "${esx_license}",
  "taskName": "workflowconfig/workflowspec-ems.json",
  "ceipEnabled": true,
  "fipsEnabled": false,
  "ntpServers": ["${ntp_server}"],
  "dnsSpec": {
    "subdomain": "${dns_domain}",
    "domain": "${dns_domain}",
    "nameserver": "${dns_server_1}",
    "secondaryNameserver" : "${dns_server_2}"
  },
  "networkSpecs": [
    {
      "networkType": "MANAGEMENT",
      "subnet": "${network_mgmt_cidr}",
      "gateway": "${network_mgmt_gateway}",
      "vlanId": "${vlan_mgmt}",
      "mtu": "9000",
      "portGroupKey": "${vcf_mgmt_domain}-${vcf_cluster_name}-vds01-pg-mgmt",
      "standbyUplinks":[],
      "activeUplinks":[
        "uplink1",
        "uplink2"
      ]
    },
    {
      "networkType": "VMOTION",
      "subnet": "${network_vmot_cidr}",
      "gateway": "${network_vmot_gateway}",
      "vlanId": "${vlan_vmot}",
      "mtu": "9000",
      "portGroupKey": "${vcf_mgmt_domain}-${vcf_cluster_name}-vds01-pg-vmotion",
      "association": "${vcf_mgmt_domain}-${vcf_dc_name}",
      "includeIpAddressRanges": [{"endIpAddress": "${network_vmot_end}", "startIpAddress": "${network_vmot_start}"}],
      "standbyUplinks":[],
      "activeUplinks":[
        "uplink1",
        "uplink2"
      ]
    },
    {
      "networkType": "VSAN",
      "subnet": "${network_vsan_cidr}",
      "gateway": "${network_vsan_gateway}",
      "vlanId": "${vlan_vsan}",
      "mtu": "9000",
      "portGroupKey": "${vcf_mgmt_domain}-${vcf_cluster_name}-vds01-pg-vsan",
      "includeIpAddressRanges": [{"endIpAddress": "${network_vsan_end}", "startIpAddress": "${network_vsan_start}"}],
      "standbyUplinks":[],
      "activeUplinks":[
        "uplink1",
        "uplink2"
      ]
    }
  ],
  "nsxtSpec":
  {
    "nsxtManagerSize": "medium",
    "nsxtManagers": [
      {
          "hostname": "nsx-t-0",
          "ip": "${nsx_t_0_ip}"
      },
      {
          "hostname": "nsx-t-1",
          "ip": "${nsx_t_1_ip}"
      },
      {
          "hostname": "nsx-t-2",
          "ip": "${nsx_t_2_ip}"
      }
    ],
    "rootNsxtManagerPassword": "${vcf_password}",
    "nsxtAdminPassword": "${vcf_password}",
    "nsxtAuditPassword": "${vcf_password}",
    "rootLoginEnabledForNsxtManager": "true",
    "sshEnabledForNsxtManager": "true",
    "overLayTransportZone": {
        "zoneName": "${vcf_mgmt_domain}-tz-overlay01",
        "networkName": "netName-overlay"
    },
    "vlanTransportZone": {
        "zoneName": "${vcf_mgmt_domain}-tz-vlan01",
        "networkName": "netName-vlan"
    },
    "vip": "${nsx_t_vip}",
    "vipFqdn": "nsx-t-vip",
    "nsxtLicense": "${nsx_t_license}",
    "transportVlanId": ${vlan_tep},
    "ipAddressPoolSpec": {
       "name": "${vcf_mgmt_domain}-${vcf_cluster_name}-tep01",
       "description": "ESXi Host Overlay TEP IP Pool",
       "subnets":[
          {
             "ipAddressPoolRanges":[
                {
                   "start": "${network_tep_start}",
                   "end": "${network_tep_end}"
                }
             ],
             "cidr": "${network_tep_cidr}",
             "gateway": "${network_tep_gateway}"
          }
       ]
    }
  },
  "vsanSpec": {
      "vsanName": "vsan-1",
      "licenseFile": "${vsan_license}",
      "vsanDedup": "false",
      "datastoreName": "${vcf_mgmt_domain}-${vcf_cluster_name}-ds-vsan01"
  },
  "dvsSpecs": [
    {
      "dvsName": "${vcf_mgmt_domain}-${vcf_cluster_name}-vds01",
      "vcenterId":"vcenter-1",
      "vmnics": [
        "vmnic0",
        "vmnic1"
      ],
      "mtu": 9000,
      "networks":[
        "MANAGEMENT",
        "VMOTION",
        "VSAN"
      ],
      "niocSpecs":[
        {
          "trafficType":"VSAN",
          "value":"HIGH"
        },
        {
          "trafficType":"VMOTION",
          "value":"LOW"
        },
        {
          "trafficType":"VDP",
          "value":"LOW"
        },
        {
          "trafficType":"VIRTUALMACHINE",
          "value":"HIGH"
        },
        {
          "trafficType":"MANAGEMENT",
          "value":"NORMAL"
        },
        {
          "trafficType":"NFS",
          "value":"LOW"
        },
        {
          "trafficType":"HBR",
          "value":"LOW"
        },
        {
          "trafficType":"FAULTTOLERANCE",
          "value":"LOW"
        },
        {
          "trafficType":"ISCSI",
          "value":"LOW"
        }
      ],
      "isUsedByNsxt": true
    }
  ],
  "clusterSpec":
  {
    "clusterName": "${vcf_mgmt_domain}-${vcf_cluster_name}",
    "vcenterName": "vcenter-1",
    "clusterEvcMode": "",
    "vmFolders": {
      "MANAGEMENT": "${vcf_mgmt_domain}-fd-mgmt",
      "NETWORKING": "${vcf_mgmt_domain}-fd-nsx",
      "EDGENODES": "${vcf_mgmt_domain}-fd-edge"
    },
    "resourcePoolSpecs": [{
      "name": "${vcf_mgmt_domain}-${vcf_cluster_name}-rp-sddc-mgmt",
      "type": "management",
      "cpuReservationPercentage": 0,
      "cpuLimit": -1,
      "cpuReservationExpandable": true,
      "cpuSharesLevel": "normal",
      "cpuSharesValue": 0,
      "memoryReservationMb": 0,
      "memoryLimit": -1,
      "memoryReservationExpandable": true,
      "memorySharesLevel": "normal",
      "memorySharesValue": 0
    }, {
      "name": "${vcf_mgmt_domain}-${vcf_cluster_name}-rp-sddc-edge",
      "type": "network",
      "cpuReservationPercentage": 0,
      "cpuLimit": -1,
      "cpuReservationExpandable": true,
      "cpuSharesLevel": "normal",
      "cpuSharesValue": 0,
      "memoryReservationPercentage": 0,
      "memoryLimit": -1,
      "memoryReservationExpandable": true,
      "memorySharesLevel": "normal",
      "memorySharesValue": 0
    }, {
      "name": "${vcf_mgmt_domain}-${vcf_cluster_name}-rp-user-edge",
      "type": "compute",
      "cpuReservationPercentage": 0,
      "cpuLimit": -1,
      "cpuReservationExpandable": true,
      "cpuSharesLevel": "normal",
      "cpuSharesValue": 0,
      "memoryReservationPercentage": 0,
      "memoryLimit": -1,
      "memoryReservationExpandable": true,
      "memorySharesLevel": "normal",
      "memorySharesValue": 0
    }, {
      "name": "${vcf_mgmt_domain}-${vcf_cluster_name}-rp-user-vm",
      "type": "compute",
      "cpuReservationPercentage": 0,
      "cpuLimit": -1,
      "cpuReservationExpandable": true,
      "cpuSharesLevel": "normal",
      "cpuSharesValue": 0,
      "memoryReservationPercentage": 0,
      "memoryLimit": -1,
      "memoryReservationExpandable": true,
      "memorySharesLevel": "normal",
      "memorySharesValue": 0
    }]
  },
  "pscSpecs": [
    {
      "pscId": "psc-1",
      "vcenterId": "vcenter-1",
      "adminUserSsoPassword": "${vcf_password}",
      "pscSsoSpec": {
        "ssoDomain": "vsphere.local"
      }
    }
  ],
  "vcenterSpec": {
      "vcenterIp": "${vcenter_ip}",
      "vcenterHostname": "vcenter",
      "vcenterId": "vcenter-1",
      "licenseFile": "${vcenter_license}",
      "vmSize": "small",
      "storageSize": "",
      "rootVcenterPassword": "${vcf_password}"
  },
  "hostSpecs": [
    {
      "association": "${vcf_mgmt_domain}-${vcf_dc_name}",
      "ipAddressPrivate": {
        "ipAddress": "${host_000_ip}"
      },
      "hostname": "${host_000_hostname}",
      "credentials": {
        "username": "root",
        "password": "${host_000_password}"
      },
      "vSwitch": "vSwitch0",
      "serverId": "host-1"
    },
    {
      "association": "${vcf_mgmt_domain}-${vcf_dc_name}",
      "ipAddressPrivate": {
        "ipAddress": "${host_001_ip}"
      },
      "hostname": "${host_001_hostname}",
      "credentials": {
        "username": "root",
        "password": "${host_001_password}"
      },
      "vSwitch": "vSwitch0",
      "serverId": "host-2"
    },
    {
      "association": "${vcf_mgmt_domain}-${vcf_dc_name}",
      "ipAddressPrivate": {
        "ipAddress": "${host_002_ip}"
      },
      "hostname": "${host_002_hostname}",
      "credentials": {
        "username": "root",
        "password": "${host_002_password}"
      },
      "vSwitch": "vSwitch0",
      "serverId": "host-3"
    },
    {
      "association": "${vcf_mgmt_domain}-${vcf_dc_name}",
      "ipAddressPrivate": {
        "ipAddress": "${host_003_ip}"
      },
      "hostname": "${host_003_hostname}",
      "credentials": {
        "username": "root",
        "password": "${host_003_password}"
      },
      "vSwitch": "vSwitch0",
      "serverId": "host-4"
    }
  ],
  "excludedComponents": ["AVN", "EBGP"]
}