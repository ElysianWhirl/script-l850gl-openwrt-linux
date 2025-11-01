#!/bin/ash

#===PLEASE DO NOT REMOVE===#
#===SCRIPT BY RUBBY_WRT====#
#===IMPROVEMENT WELCOME====#
#===COPYRIGHT SCRIPT=======#

# Define the target hosts to ping
target1="your_host"
target2="your_host"
target3="your_host"

# Ping settings
interval=1
timeout=1
count=1

interface="wwan0"
tunnel="nikki"

# === KONFIGURASI BARU ===
# Pilihan: "yes" atau "no"
restart_tunnel="no"   # Ubah ke "no" jika tidak ingin otomatis restart tunnel

# Thresholds
consecutive_failed=3
wan_ip_failed=3

# Counters
failed_count_target1=0
failed_count_target2=0
failed_count_target3=0
wan_ip_not_available=0

# Loop indefinitely
while :
do
    current_time=$(date "+%Y-%m-%d %H:%M:%S")

    # === CEK APAKAH INTERFACE WWAN0 ADA ===
    if ! ip link show "$interface" >/dev/null 2>&1; then
        echo "$current_time - $interface interface not found. Skipping checks. Check modem/driver."
        sleep "$interval"
        continue
    fi

    # === AMBIL IP DARI INTERFACE ===
    wan_ip=$(ip -4 addr show "$interface" | awk '/inet / {print $2}' | cut -d "/" -f 1)

    if [ -z "$wan_ip" ]; then
        echo "$current_time - $interface interface exists but has no IP. Count: $wan_ip_not_available"
        wan_ip_not_available=$((wan_ip_not_available + 1))

        if [ $wan_ip_not_available -ge $wan_ip_failed ]; then
            echo "$current_time - $interface IP unavailable for $wan_ip_failed checks. Running recreate.sh..."
            if /etc/modrak/recreate.sh; then
                echo "$current_time - $interface: recreate interface executed successfully"

                if [ "$restart_tunnel" = "yes" ]; then
                    echo "$current_time - $interface: Attempting to restart service $tunnel..."
                    if service "$tunnel" restart; then
                        echo "$current_time - $interface: service $tunnel restarted successfully"
                    else
                        echo "$current_time - $interface: FAILED to restart service $tunnel"
                    fi
                else
                    echo "$current_time - $interface: restart_tunnel is set to 'no'. Skipping tunnel restart."
                fi
            else
                echo "$current_time - $interface: recreate interface execution failed"
            fi
            wan_ip_not_available=0
        fi

    else
        # Reset counter karena IP tersedia
        wan_ip_not_available=0

        all_targets_failed=1

        # === PING TARGET 1 via $interface ===
        ping_result=$(ping -I "$interface" -c "$count" -W "$timeout" "$target1" 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - $interface IP: $wan_ip: Ping to $target1 OK (Response time: ${response_time:-?} ms)"
            failed_count_target1=0
            all_targets_failed=0
        else
            echo "$current_time - $interface IP: $wan_ip: Ping to $target1 failed"
            failed_count_target1=$((failed_count_target1 + 1))
        fi

        # === PING TARGET 2 via $interface ===
        ping_result=$(ping -I "$interface" -c "$count" -W "$timeout" "$target2" 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - $interface IP: $wan_ip: Ping to $target2 OK (Response time: ${response_time:-?} ms)"
            failed_count_target2=0
            all_targets_failed=0
        else
            echo "$current_time - $interface IP: $wan_ip: Ping to $target2 failed"
            failed_count_target2=$((failed_count_target2 + 1))
        fi

        # === PING TARGET 3 via $interface ===
        ping_result=$(ping -I "$interface" -c "$count" -W "$timeout" "$target3" 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - $interface IP: $wan_ip: Ping to $target3 OK (Response time: ${response_time:-?} ms)"
            failed_count_target3=0
            all_targets_failed=0
        else
            echo "$current_time - $interface IP: $wan_ip: Ping to $target3 failed"
            failed_count_target3=$((failed_count_target3 + 1))
        fi

        # === CEK JIKA SEMUA TARGET GAGAL BERTURUT-TURUT ===
        if [ $all_targets_failed -eq 1 ] && \
           [ $failed_count_target1 -ge $consecutive_failed ] && \
           [ $failed_count_target2 -ge $consecutive_failed ] && \
           [ $failed_count_target3 -ge $consecutive_failed ]; then

            echo "$current_time - $interface IP: $wan_ip: All targets failed $consecutive_failed+ times. Running modpes.sh..."
            if /etc/modrak/modpes.sh; then
                echo "$current_time - $interface IP: $wan_ip: modpes.sh executed successfully"

                if [ "$restart_tunnel" = "yes" ]; then
                    echo "$current_time - $interface IP: $wan_ip: Attempting to restart service $tunnel..."
                    if service "$tunnel" restart; then
                        echo "$current_time - $interface IP: $wan_ip: service $tunnel restarted successfully"
                    else
                        echo "$current_time - $interface IP: $wan_ip: FAILED to restart service $tunnel"
                    fi
                else
                    echo "$current_time - $interface IP: $wan_ip: restart_tunnel is set to 'no'. Skipping tunnel restart."
                fi
            else
                echo "$current_time - $interface IP: $wan_ip: modpes.sh execution failed"
            fi

            # Reset counters setelah tindakan
            failed_count_target1=0
            failed_count_target2=0
            failed_count_target3=0
        fi
    fi

    sleep "$interval"
done
