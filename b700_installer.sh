#!/bin/sh
#script by Abi Darwish

cat << 'EOF' > /root/bypass700.sh
#!/bin/sh
#script by Abi Darwish

INTERRUPT=$(ls /proc/irq/ | sed '/default/d')
USB3_NUMBER=$(grep usb3 /proc/interrupts | awk -F: '{print $1}' | sed 's/^ //')

for I in ${INTERRUPT}; do
	if [[ ${I} = ${USB3_NUMBER} ]]; then
        	echo f > /proc/irq/${I}/smp_affinity 2>/dev/null
        else
        	echo e > /proc/irq/${I}/smp_affinity 2>/dev/null
        fi
        printf "%-10s" ${I}:
        cat /proc/irq/${I}/smp_affinity
done
EOF
sed -i '/bypass700/d' /etc/rc.local
sed -i '/exit 0/ish /root/bypass700.sh' /etc/rc.local

if [[ ! -e /etc/hotplug.d/net/20-smp-tune.bak ]]; then
    cp /etc/hotplug.d/net/20-smp-tune /etc/hotplug.d/net/20-smp-tune.bak
fi

cat << 'EOF' > /etc/hotplug.d/net/20-smp-tune
#!/bin/sh
#script by Abi Darwish

echo 2 > /sys/class/net/br-lan/queues/rx-0/rps_cpus
echo f > /sys/class/net/wwan0/queues/rx-0/rps_cpus
echo f > /sys/class/net/wwan0_1/queues/rx-0/rps_cpus
echo f > /sys/class/net/wifi0/queues/rx-0/rps_cpus
echo 4 > /sys/class/net/wifi1/queues/rx-0/rps_cpus
echo 1 > /sys/class/net/eth0/queues/rx-0/rps_cpus
echo f > /sys/class/net/eth0/queues/rx-0/rps_cpus
echo f > /sys/class/net/eth1/queues/rx-0/rps_cpus
echo f > /sys/class/net/eth2/queues/rx-0/rps_cpus
echo f > /sys/class/net/eth3/queues/rx-0/rps_cpus
echo f > /sys/class/net/eth4/queues/rx-0/rps_cpus
EOF

rm -rf /root/b700_installer.sh
sh /root/bypass700.sh
sh /etc/hotplug.d/net/20-smp-tune
