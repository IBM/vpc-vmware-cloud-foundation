#######################################
# ESXi Userdata for VCF deployment    #
#######################################

# Enable & start SSH 
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

# Enable & start ESXi Shell
vim-cmd hostsvc/enable_esx_shell
vim-cmd hostsvc/start_esx_shell

# Set the hostname
esxcli system hostname set --fqdn=${hostname_fqdn}

# Update SSL Certificate with new fqdn
/sbin/generate-certificates

# Update MTU to Jumbo frames
esxcli network vswitch standard set -m 9000 -v vSwitch0

# Create a new portgroup for Instance Management  
esxcfg-vswitch vSwitch0 --add-pg=pg-mgmt
esxcfg-vswitch vSwitch0 --pg=pg-mgmt --vlan=${mgmt_vlan}

# Change VM network portgroup VLAN
esxcfg-vswitch vSwitch0 --pg="VM Network" --vlan=${mgmt_vlan}

# Create a new vmk1 to a match the new VLAN interface
esxcli network ip interface add --interface-name=vmk1 --portgroup-name=pg-mgmt
esxcli network ip interface ipv4 set --interface-name=vmk1 --ipv4=${new_mgmt_ip_address} --netmask=${new_mgmt_netmask}  --type=static

# Mark vmk1 for management traffic
esxcli network ip interface tag add -i vmk1 -t Management
esxcli network ip interface tag remove -i vmk0 -t Management

# Update default gateway
esxcli network ip route ipv4 add --gateway=${new_mgmt_default_gateway} --network=default

# Add NTP Server addresses
esxcli system ntp set --server 161.26.0.6

# Allow NTP through firewall
esxcfg-firewall -e ntpClient

# Enable NTP autostartup
/sbin/chkconfig ntpd on

# Start NTP
/etc/init.d/ntpd start

# Remove old vmk0 and change "Management Network" pg vlan id
esxcfg-vswitch vSwitch0 --pg="Management Network" --vlan=${mgmt_vlan}
esxcli network ip interface remove --interface-name=vmk0

# Restart
/etc/init.d/hostd restart
/etc/init.d/vpxa restart


# Force boot host ... not needed if the restart works...and there will be a boot when adding a PCI nic 2

#esxcli system shutdown reboot -d 60 -r "vmk0 - VLAN Nic Add"
