RENEWAL_INTERVAL_MINUTES=30
RETRY_ATTEMPTS=5
RETRY_DELAY_SECONDS=10

renew_tokens() {
    while true; do
        local success=true
        
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Starting token renewal."
        
        # 1. Fetch BUS CREDS (and save to client mount path)
        # --retry: attempts to fetch this many times
        # --retry-delay: seconds to wait between retries
        if ! curl -s --fail --retry "$RETRY_ATTEMPTS" --retry-delay "$RETRY_DELAY_SECONDS" "$BUS_CREDS_LINK" > "$CLIENT_CREDS_FILE_PATH"; then
            echo "ERROR: Failed to fetch BUS CREDS after $RETRY_ATTEMPTS attempts."
            success=false
        else
            echo "Successfully updated $CLIENT_CREDS_FILE_PATH"
        fi

        # 2. Fetch CLIENT CREDS (and save to bus mount path)
        if ! curl -s --fail --retry "$RETRY_ATTEMPTS" --retry-delay "$RETRY_DELAY_SECONDS" "$CLIENT_CREDS_LINK" > "$CLIENT_CREDS_FILE_PATH"; then
            echo "ERROR: Failed to fetch CLIENT CREDS after $RETRY_ATTEMPTS attempts."
            success=false
        else
            echo "Successfully updated $CLIENT_CREDS_FILE_PATH"
        fi
        
        if [ "$success" = true ]; then
            echo "Renewal cycle complete. Waiting $RENEWAL_INTERVAL_MINUTES minutes..."
        else
            echo "Renewal cycle finished with errors. Will retry in $RENEWAL_INTERVAL_MINUTES minutes."
        fi

        sleep $((RENEWAL_INTERVAL_MINUTES * 60))

    done
}