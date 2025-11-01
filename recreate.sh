#!/bin/sh
#===PLEASE DO NOT REMOVE===#
#===SCRIPT BY RUBBY_WRT====#
#===IMPROVEMENT WELCOME====#
#===COPYRIGHT SCRIPT=======#

interface=wwan0
gtw_metric=1

uci delete network.$interface 2>/dev/null
uci commit network
echo "delete $interface berhasil"
/etc/init.d/network reload
sleep 1

uci set network.$interface=interface
uci set network.$interface.proto='modemmanager'
uci set network.$interface.device='/sys/devices/platform/soc/d0078080.usb/c9000000.usb/xhci-hcd.3.auto/usb1/1-1'
uci set network.$interface.apn='internet'
uci add_list network.$interface.allowedauth='none'
uci set network.$interface.iptype='ipv4v6'
uci set network.$interface.loglevel='ERR'

# === TAMBAHAN: GATEWAY METRIC, DNS, DAN FORCE LINK ===
uci set network.$interface.metric='$gtw_metric'      # Prioritas routing tinggi
uci set network.$interface.peerdns='1'     # Gunakan DNS dari provider
uci set network.$interface.force_link='1'  # Force link = centang di LuCI

uci commit network
echo "Konfigurasi $interface berhasil direcreate"
/etc/init.d/network reload
