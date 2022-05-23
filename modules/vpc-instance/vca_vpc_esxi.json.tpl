{
   "__version": "2.13.0",
   "new_vcsa": {
       "esxi": {
           "hostname": "${vcenter_esx_hostname_fqdn}",
           "username": "root",
           "password": "${vcenter_esx_pwd}",
           "deployment_network": "pg-mgmt",
           "datastore": "datastore1"
       },
       "appliance": {
           "thin_disk_mode": true,
           "deployment_option": "small",
           "name": "vcenter"
       },
       "network": {
           "ip_family": "ipv4",
           "mode": "static",
           "system_name": "vcenter.${domain}",
           "ip": "${vcenter_ip}",
           "prefix": "${network_cidrprefix}",
           "gateway": "${network_gateway}",
           "dns_servers": [
               "161.26.0.7,161.26.0.8"
           ]
       },
       "os": {
           "password": "${vcenter_pwd}",
           "ntp_servers": "161.26.0.6",
           "ssh_enable": false
       },
       "sso": {
           "password": "${vcenter_pwd}",
           "domain_name": "${domain}"
       }
   },
   "ceip": {
       "settings": {
           "ceip_enabled": false
       }
   }
}