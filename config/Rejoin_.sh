#!/system/bin/sh
echo "Loading..."
if ! command -v sqlite3 >/dev/null 2>&1; then
    pkg update && pkg upgrade -y && pkg install -y sqlite && pkg install jq >/dev/null 2>&1
fi
ROBLOX_PACKAGES=($(pm list packages | grep roblox | cut -d: -f2))
WEBHOOK_URL2="https://discord.com/api/webhooks/1340266932707917855/dr6Krtq22v1y-YAoosniv2GO5TRyrbK92yh_9Nn30NhRaqK4w3OqZX_vEZOoYTeY2NJJ"
CONFIG_FILE="$HOME/Downloads/ConfigRejoin.txt"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    GameID="2753915549"
    TimeRejoin=60
    RobloxTab=0
fi
if [ "$RobloxTab" -gt 0 ] && [ "$RobloxTab" -lt "${#ROBLOX_PACKAGES[@]}" ]; then
    ROBLOX_PACKAGES=(${ROBLOX_PACKAGES[@]:0:$RobloxTab})
fi
declare -A LAST_RESTART_TIMES
for pkg in "${ROBLOX_PACKAGES[@]}"; do
    LAST_RESTART_TIMES[$pkg]=0
    echo "Đã Tạo Lịch Restart Cho $pkg"
done
force_restart() {
    local pkg=$1
    echo "Đóng Roblox Cho $pkg"
    su -c "am force-stop $pkg" >/dev/null 2>&1
    sleep 3
    echo "Mở Roblox Cho $pkg"
    am start -n ${pkg}/com.roblox.client.startup.ActivitySplash -d "roblox://placeID=${GameID}" >/dev/null 2>&1
    sleep 10
    echo "Vào GameID $GameID Cho $pkg"
    am start -n ${pkg}/com.roblox.client.ActivityProtocolLaunch -d "roblox://placeID=${GameID}" >/dev/null 2>&1
    LAST_RESTART_TIMES[$pkg]=$(date +%s)
}
check_and_restart() {
    while true; do
        sleep 60
        for pkg in "${ROBLOX_PACKAGES[@]}"; do
            if ! su -c "ps -A | awk '$NF=="'$pkg'"'" >/dev/null; then
                echo "$pkg Không Hoạt Động, Restart"
                force_restart "$pkg"
            fi
        done
    done
}
auto_restart() {
    while true; do
        CURRENT_TIME=$(date +%s)
        for pkg in "${ROBLOX_PACKAGES[@]}"; do
            LAST_RESTART_TIME=${LAST_RESTART_TIMES[$pkg]:-0}
            if [ $((CURRENT_TIME - LAST_RESTART_TIME)) -ge $((TimeRejoin*60)) ]; then
                force_restart $pkg
            fi
        done
    done
}
auto_restart &
check_and_restart &
