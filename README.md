# esxi-shutdown #
A modified version of `shutdown.sh` that gracefully shuts down autostop-configured VMs

The key change compared to the original `shutdown.sh` included in ESXi pre-v7 is it will start the autostop sequence and actually wait for the VMs to finish shutting down (or to reach `$TIMEOUT`) before stopping the host.