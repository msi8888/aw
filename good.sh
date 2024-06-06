#!/bin/sh
if [[ ! -z $(which irqbalance) ]]; then
	sed -i "s/enabled \'1\'/enabled \'0\'/" /etc/config/irqbalance
	/etc/init.d/irqbalance stop
	opkg remove irqbalance
fi

if [[ -z $(which htop) ]]; then
	opkg update
	opkg install htop
fi

if [[ -e /etc/hotplug.d/net/20-smp-tune && ! -e /etc/hotplug.d/net/20-smp-tune.bak ]]; then
	[[ ! -e /etc/arca ]] && mkdir -p /etc/arca
	mv /etc/hotplug.d/net/20-smp-tune /etc/arca/20-smp-tune
fi

cat << 'EOF' > /etc/hotplug.d/net/20-smp-tune
#!/bin/sh

INTERRUPT=$(ls /proc/irq/ | sed '/default/d')
USB3_NUMBER=$(grep usb3 /proc/interrupts | awk -F: '{print $1}' | sed 's/^ //')

for i in ${INTERRUPT}; do
	if [[ $i = ${USB3_NUMBER} ]]; then
        	echo f > /proc/irq/$i/smp_affinity 2>/dev/null
        else
        	echo e > /proc/irq/$i/smp_affinity 2>/dev/null
        fi
done

IFACE=$(ls /sys/class/net)

for i in ${IFACE}; do
	ethtool -K $i gro on 2>/dev/null
	if [[ -e /sys/class/net/$i/queues/rx-0/rps_cpus ]]; then
		if [[ $i = "wwan0_1" ]]; then
			echo f > /sys/class/net/$i/queues/rx-0/rps_cpus
		else
			echo f > /sys/class/net/$i/queues/rx-0/rps_cpus
		fi
	fi
done
EOF

cat << 'EOF' > /etc/sysctl.d/99-gaza.conf
#memory optimized
vm.min_free_kbytes=1
vm.vfs_cache_pressure=500
vm.overcommit_memory=0
vm.overcommit_ratio=10
vm.dirty_ratio=20
vm.dirty_expire_centisecs=1500
vm.drop_caches=3
#Network Tweak Control
# allow testing with buffers up to 64MB 
net.core.rmem_max=67108864 
net.core.wmem_max=67108864 
# increase Linux autotuning TCP buffer limit to 32MB
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
# recommended default congestion control is htcp 
#net.ipv4.tcp_congestion_control = bbr
# recommended for hosts with jumbo frames enabled
net.ipv4.tcp_mtu_probing=1
#Others
fs.file-max=1000000
fs.inotify.max_user_instances=8192
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_max_syn_backlog=1024
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30
net.ipv4.tcp_synack_retries=3
#BETA
net.ipv4.tcp_max_tw_buckets=6000
net.ipv4.route.gc_timeout=100
net.core.somaxconn=32768
net.ipv4.tcp_max_orphans=32768
net.core.netdev_max_backlog=2000
net.netfilter.nf_conntrack_max=65535
net.core.rmem_default=256960
net.core.wmem_default=256960
net.core.optmem_max=81920
net.ipv4.tcp_mem=131072  262144  524288
net.ipv4.tcp_keepalive_time=1800
EOF

sh /etc/hotplug.d/net/20-smp-tune
sysctl -p -q /etc/sysctl.d/99-gaza.conf

sed -i '/bypass700.sh/d' /etc/rc.local
sed -i '/gro.sh/d' /etc/rc.local
rm -rf /root/gro.sh
rm -rf /root/output.txt
rm -rf /root/good.sh
echo
echo -e "Successful..."
echo
exit 0
