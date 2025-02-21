#!/bin/bash

check_user_status() {
    local username="$1"
    local user_id=$(curl -s -X POST "https://users.roblox.com/v1/usernames/users" \
        -H "Content-Type: application/json" \
        -d "{\"usernames\": [\"$username\"], \"excludeBannedUsers\": true}" | jq -r '.data[0].id // empty')
    
    if [[ -z "$user_id" || "$user_id" == "null" ]]; then
        echo "-1"
        return
    fi

    local response=$(curl -s -X POST "https://presence.roblox.com/v1/presence/users" \
        -H "Content-Type: application/json" \
        -d "{\"userIds\": [$user_id]}" | jq -r '.userPresences[0].userPresenceType')
    
    if [[ -z "$response" || "$response" == "null" ]]; then
        echo "-1"
    else
        echo "$response"
    fi
}

check_user_status "$1"
