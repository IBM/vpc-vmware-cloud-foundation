# Enable & start SSH
vim-cmd hostsvc/enable_ssh
vim-cmd hostsvc/start_ssh

# Enable & start ESXi Shell
vim-cmd hostsvc/enable_esx_shell
vim-cmd hostsvc/start_esx_shell

# Set the hostname
esxcli system hostname set --fqdn=${hostname_fqdn}

# Create a portgroup for vCenter  
esxcfg-vswitch vSwitch0 --add-pg=pg-mgmt
esxcfg-vswitch vSwitch0 --pg=pg-mgmt --vlan=${mgmt_vlan}

# restart mgmt to pick up changes
/etc/init.d/hostd restart
/etc/init.d/vpxa restart
# END



