#!/bin/ash

uci delete network.wwan0 2>/dev/null
uci commit network
echo "delete wwan0 berhasil"
/etc/init.d/network reload

uci set network.wwan0=interface
uci set network.wwan0.proto='modemmanager'
uci set network.wwan0.device='/sys/devices/pci0000:00/0000:00:14.0/usb4/4-1'
uci set network.wwan0.apn='internet'
uci add_list network.wwan0.allowedauth='none'
uci set network.wwan0.iptype='ipv4v6'
uci set network.wwan0.loglevel='ERR'
uci set network.wwan0.dns_metric='1'
uci set network.wwan0.metric='1'
uci commit network
echo "Konfigurasi wwan0 berhasil direcreate"
/etc/init.d/network reload
