# Enable & start SSH
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

# Enable & start ESXi Shell
vim-cmd hostsvc/enable_esx_shell
vim-cmd hostsvc/start_esx_shell

# Set the hostname
esxcli system hostname set --fqdn=${hostname_fqdn}

# Add DNS Server addresses

esxcli network ip dns server remove --all
esxcli network ip dns server add --server=${dns_server_1}
esxcli network ip dns server add --server=${dns_server_2}

# Add NTP Server addresses
esxcli system ntp set --server=161.26.0.6

# Create a portgroup for vCenter  
esxcfg-vswitch vSwitch0 --add-pg=pg-mgmt
esxcfg-vswitch vSwitch0 --pg=pg-mgmt --vlan=${mgmt_vlan}

# restart mgmt to pick up changes
/etc/init.d/hostd restart
/etc/init.d/vpxa restart
# END



