#!/bin/bash

get_user_info() {
    local username="$1"
    local response=$(curl -s -X POST "https://users.roblox.com/v1/usernames/users" \
        -H "Content-Type: application/json" \
        -d "{\"usernames\": [\"$username\"], \"excludeBannedUsers\": true}")
    
    user_id=$(echo "$response" | jq -r '.data[0].id // empty')
    name=$(echo "$response" | jq -r '.data[0].name // empty')
    display_name=$(echo "$response" | jq -r '.data[0].displayName // empty')
    
    if [[ -z "$user_id" ]]; then
        echo "Không tìm thấy người dùng."
        exit 1
    fi
}

check_user_status() {
    local user_id="$1"
    local name="$2"
    local display_name="$3"
    
    local response=$(curl -s -X POST "https://presence.roblox.com/v1/presence/users" \
        -H "Content-Type: application/json" \
        -d "{\"userIds\": [$user_id]}")
    
    local status_code=$(echo "$response" | jq -r '.userPresences[0].userPresenceType // empty')
    
    case "$status_code" in
        0) status="Ngoại Tuyến" ;;
        1) status="Trực Tuyến" ;;
        2) status="Đang Trong Game" ;;
        *) status="Không Xác Định" ;;
    esac
    
    echo "$name | $display_name | $status"
}

main() {
    local username="$1"
    get_user_info "$username"
    check_user_status "$user_id" "$name" "$display_name"
}

if [[ "$#" -ne 1 ]]; then
    echo "Usage: $(basename "$0") <username>"
    exit 1
fi

main "$1"
