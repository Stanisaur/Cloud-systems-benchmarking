#!/bin/bash
# Contains the main setup function for creating networks and gateways.

setup() {
    log_info "--- Running Setup ---"
    local TEMP_ALL_IPS
    TEMP_ALL_IPS=$(mktemp)
    local TEMP_ACTIVE_IPS
    TEMP_ACTIVE_IPS=$(mktemp)
    local GATEWAY_ID_FILE="$STATE_DIR/gateway_ids.txt"

    log_info "1. Creating macvlan network interface..."
    docker network create -d macvlan -o parent="$PARENT_INTERFACE" --subnet="$TARGET_SUBNET" macvlan_net >/dev/null 2>&1 || true

    log_info "2. Finding available IPs in subnet $TARGET_SUBNET..."
    nmap -sL -n "$TARGET_SUBNET" 2>/dev/null | \
        awk '/Nmap scan report for/ { ip = $NF; split(ip, octets, "."); if (octets[4] != "0" && octets[4] != "255") print ip; }' | \
        sort > "$TEMP_ALL_IPS"

    nmap -sn -n -T4 -PR -PS22,80,443 -PU53 -oG - "$TARGET_SUBNET" 2>/dev/null | \
        awk '/Up$/{print $2}' | sort > "$TEMP_ACTIVE_IPS"

    mapfile -t AVAILABLE_IPS < <(comm -23 "$TEMP_ALL_IPS" "$TEMP_ACTIVE_IPS")
    rm -f "$TEMP_ALL_IPS" "$TEMP_ACTIVE_IPS"

    log_info "   Found ${#AVAILABLE_IPS[@]} unassigned IPs."
    if [ "${#AVAILABLE_IPS[@]}" -lt "$NUM_IPS" ]; then
        log_warning "Not enough available IPs (${#AVAILABLE_IPS[@]}) for the requested number of gateways ($NUM_IPS)."
        NUM_IPS=${#AVAILABLE_IPS[@]}
        log_warning "         Proceeding with $NUM_IPS gateways."
    fi

    log_info "3. Starting up $NUM_IPS SNAT gateway containers..."
    for (( i=1; i<=NUM_IPS; i++ )); do
        local ip_index=$((i - 1))
        local mobile_subnet="10.10.${i}.0/24"
        local network_name="${MOBILE_NETWORK_PREFIX}_${i}"
        local gateway_name="snat_gateway_${i}"
        local gateway_ip="${AVAILABLE_IPS[$ip_index]}"

        docker network create --subnet="$mobile_subnet" "$network_name" >/dev/null

        local new_gateway_id
        new_gateway_id=$(docker run -d \
            --network macvlan_net \
            --user root --cap-add NET_ADMIN \
            --sysctl net.ipv4.ip_forward=1 \
            --ip "$gateway_ip" \
            --name "$gateway_name" \
            --hostname "$gateway_name" \
            nicolaka/netshoot /bin/sh -c "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; \
            tc qdisc replace dev eth0 root netem delay ${U_LATENCY}ms ${U_JITTER}ms ${CORRELATION}% loss ${U_LOSS}%; sleep infinity")
        
        echo "$new_gateway_id" >> "$GATEWAY_ID_FILE"
        docker network connect "$network_name" "$gateway_name" >/dev/null
        docker exec -d "$new_gateway_id" tc qdisc replace dev eth1 root netem delay ${D_LATENCY}ms ${D_JITTER}ms ${CORRELATION}% loss ${D_LOSS}% >/dev/null
        # log_info "   -> Gateway ${gateway_name} created with IP ${gateway_ip} on network ${network_name}"
    done
    log_success "--- Setup Complete ---"
}