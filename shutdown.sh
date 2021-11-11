#!/bin/ash
# This is a modified version of the shutdown.sh that was included in ESXi pre-v7
# It shuts down all VMs, waits for them to fully shutdown, and then powers off the host

# Check if a custom timeout was passed
if [ -z $1 ]; then
    TIMEOUT=60
else
    TIMEOUT=$1
fi
echo "VM shutdown timeout set to $TIMEOUT"

log() {
   echo "$1"
   logger init "$1"
}

# Extract and save the random seed
# this was in the original script, i don't know why
dd if=/dev/urandom of=/etc/random-seed count=1 2>/dev/null

# Power off autostop-configured VMs
/sbin/vim-cmd hostsvc/autostartmanager/autostop

# When we should stop polling the VM process list
END_TIMESTAMP=$(($(date +%s) + $TIMEOUT))
echo "Waiting $(($END_TIMESTAMP - $(date +%s))) seconds for $(esxcli vm process list | grep "World ID:"| wc -l) VMs to shutdown..."

# Continously poll the VM process list until all VMs have shutdown or the timeout was reached
while [ $(esxcli vm process list | grep "World ID:"| wc -l) -gt 1 ] && [ $(date +%s) -lt $END_TIMESTAMP ]
do
    echo "Waiting $(($END_TIMESTAMP - $(date +%s))) seconds for $(esxcli vm process list | grep "World ID:"| wc -l) VMs to shutdown: $(esxcli vm process list | awk -e '/Display Name:/{ $1 = ""; $2 = ""; sub(/^[ \t]+/, ""); printf "%s, ", $0 }')"
    sleep 1
done

# Check if any VMs still didn't shutdown
if [ $(esxcli vm process list | grep "World ID:"| wc -l) -gt 1 ]; then
    echo "Timeout reached, $(esxcli vm process list | grep "World ID:"| wc -l) VMs did not shutdown: $(esxcli vm process list | awk -e '/Display Name:/{ $1 = ""; $2 = ""; sub(/^[ \t]+/, ""); printf "%s, ", $0 }')"
else
    echo "VM shutdown completed in $(($TIMEOUT - $(($END_TIMESTAMP - $(date +%s))))) seconds"
fi

# Stop running services
/sbin/services.sh stop

# Backup the config (including the random seed)
/sbin/backup.sh 1

# Shutdown syslog daemon
/usr/lib/vmware/vmsyslog/bin/shutdown.sh

# Poweroff the host
/sbin/poweroff
