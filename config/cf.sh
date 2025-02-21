#!/bin/bash
check_user_status() {
    local username="$1"
    local user_id=$(curl -s -X POST "https://users.roblox.com/v1/usernames/users" \
        -H "Content-Type: application/json" \
        -d "{\"usernames\": [\"$username\"], \"excludeBannedUsers\": true}" | jq -r '.data[0].id // empty')
    if [[ -n "$user_id" ]]; then
        curl -s -X POST "https://presence.roblox.com/v1/presence/users" \
            -H "Content-Type: application/json" \
            -d "{\"userIds\": [$user_id]}" | jq -r '.userPresences[0].userPresenceType // -1'
    else
        echo "-1"
    fi
}
check_user_status "Rdthaiphno064"
