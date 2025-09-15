#!/bin/ash

# Define the target hosts to ping
target1="your_host"
target2="your_host"
target3="your_host"   # Fixed typo

# Ping settings
interval=1
timeout=1
count=1

tunnel=nikki

# Thresholds
consecutive_failed=3
wan_ip_failed=5

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
    if ! ip link show wwan0 >/dev/null 2>&1; then
        echo "$current_time - WWAN0 interface not found. Skipping recreate. Check modem/driver."
        sleep $interval
        continue   # Lewati semua logika ping & recreate jika interface tidak ada
    fi

    # === AMBIL IP DARI WWAN0 ===
    usb0_ip=$(ip -4 addr show wwan0 | awk '/inet / {print $2}' | cut -d "/" -f 1)

    if [ -z "$usb0_ip" ]; then
        echo "$current_time - WWAN0 interface exists but has no IP. Count: $wan_ip_not_available"
        wan_ip_not_available=$((wan_ip_not_available + 1))

        # Jika gagal dapat IP berturut-turut >= threshold, jalankan recreate.sh
        if [ $wan_ip_not_available -ge $wan_ip_failed ]; then
            echo "$current_time - WWAN0 IP unavailable for $wan_ip_failed checks. Running recreate.sh..."
            if /root/modrak/recreate.sh; then
                echo "$current_time - WWAN0: recreate interface executed successfully"
                # Jalankan restart service $tunnel setelah recreate.sh sukses
                if service $tunnel restart; then
                    echo "$current_time - WWAN0: service $tunnel restarted successfully"
                else
                    echo "$current_time - WWAN0: FAILED to restart service $tunnel"
                fi
            else
                echo "$current_time - WWAN0: recreate interface execution failed"
            fi
            wan_ip_not_available=0  # Reset counter setelah coba recreate
        fi

    else
        # Reset counter karena IP tersedia
        wan_ip_not_available=0

        # Asumsikan semua target gagal, kecuali ada yang sukses
        all_targets_failed=1

        # Ping target 1
        ping_result=$(ping -c $count -W $timeout $target1 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target1 OK (Response time: ${response_time:-?} ms)"
            failed_count_target1=0
            all_targets_failed=0
        else
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target1 failed"
            failed_count_target1=$((failed_count_target1 + 1))
        fi

        # Ping target 2
        ping_result=$(ping -c $count -W $timeout $target2 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target2 OK (Response time: ${response_time:-?} ms)"
            failed_count_target2=0
            all_targets_failed=0
        else
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target2 failed"
            failed_count_target2=$((failed_count_target2 + 1))
        fi

        # Ping target 3
        ping_result=$(ping -c $count -W $timeout $target3 2>/dev/null)
        if [ $? -eq 0 ]; then
            response_time=$(echo "$ping_result" | awk -F'[= ]+' '/time=/ {for(i=1;i<=NF;i++) if($i=="time") print $(i+1)}' | head -1)
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target3 OK (Response time: ${response_time:-?} ms)"
            failed_count_target3=0
            all_targets_failed=0
        else
            echo "$current_time - WWAN0 IP: $usb0_ip: Ping to $target3 failed"
            failed_count_target3=$((failed_count_target3 + 1))
        fi

        # Jika semua target gagal berturut-turut >= threshold
        if [ $all_targets_failed -eq 1 ] && \
           [ $failed_count_target1 -ge $consecutive_failed ] && \
           [ $failed_count_target2 -ge $consecutive_failed ] && \
           [ $failed_count_target3 -ge $consecutive_failed ]; then

            echo "$current_time - WWAN0 IP: $usb0_ip: All targets failed $consecutive_failed+ times. Running modpes.sh..."
            if /root/modrak/modpes.sh; then
                echo "$current_time - WWAN0 IP: $usb0_ip: modpes.sh executed successfully"
                # Jalankan restart service $tunnel setelah modpes.sh sukses
                if service $tunnel restart; then
                    echo "$current_time - WWAN0 IP: $usb0_ip: service $tunnel restarted successfully"
                else
                    echo "$current_time - WWAN0 IP: $usb0_ip: FAILED to restart service $tunnel"
                fi
            else
                echo "$current_time - WWAN0 IP: $usb0_ip: modpes.sh execution failed"
            fi

            # Reset counters
            failed_count_target1=0
            failed_count_target2=0
            failed_count_target3=0
        fi
    fi

    sleep $interval
done
