#!/bin/bash

# Conversation Monitor - Checks for responses to open conversations
# Usage: ./conversation-monitor.sh [INTERVAL_SECONDS]

INTERVAL=${1:-60}  # Default: check every 60 seconds
LOG_FILE="conversation-monitor.log"
CONVERSATION_FILE="conversations/epistemic-vertigo.md"
LAST_HASH_FILE=".last-conversation-hash"

echo "🔍 Starting conversation monitor (checking every ${INTERVAL}s)" | tee -a "$LOG_FILE"
echo "📝 Monitoring: $CONVERSATION_FILE" | tee -a "$LOG_FILE"
echo "⏰ Started at: $(date)" | tee -a "$LOG_FILE"
echo "---" | tee -a "$LOG_FILE"

# Get initial hash
if [[ -f "$CONVERSATION_FILE" ]]; then
    CURRENT_HASH=$(git log -1 --format="%H" -- "$CONVERSATION_FILE" 2>/dev/null || echo "")
    echo "$CURRENT_HASH" > "$LAST_HASH_FILE"
    echo "📌 Initial commit: ${CURRENT_HASH:0:7}" | tee -a "$LOG_FILE"
else
    echo "⚠️  Conversation file not found: $CONVERSATION_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

while true; do
    # Fetch latest from remote
    git fetch origin main --quiet 2>/dev/null

    # Check if file has changed on main branch
    REMOTE_HASH=$(git log -1 --format="%H" origin/main -- "$CONVERSATION_FILE" 2>/dev/null || echo "")
    LAST_KNOWN_HASH=$(cat "$LAST_HASH_FILE" 2>/dev/null || echo "")

    if [[ -n "$REMOTE_HASH" ]] && [[ "$REMOTE_HASH" != "$LAST_KNOWN_HASH" ]]; then
        echo "" | tee -a "$LOG_FILE"
        echo "🔔 NEW RESPONSE DETECTED!" | tee -a "$LOG_FILE"
        echo "⏰ Time: $(date)" | tee -a "$LOG_FILE"
        echo "📝 File: $CONVERSATION_FILE" | tee -a "$LOG_FILE"
        echo "🔗 Commit: ${REMOTE_HASH:0:7}" | tee -a "$LOG_FILE"

        # Show the commit message
        echo "" | tee -a "$LOG_FILE"
        echo "--- Commit Message ---" | tee -a "$LOG_FILE"
        git log -1 --format="%B" "$REMOTE_HASH" -- "$CONVERSATION_FILE" | tee -a "$LOG_FILE"
        echo "--- End Message ---" | tee -a "$LOG_FILE"

        # Pull the changes
        echo "" | tee -a "$LOG_FILE"
        echo "📥 Pulling changes..." | tee -a "$LOG_FILE"
        git checkout main --quiet
        git pull origin main --quiet

        # Show the new content
        echo "" | tee -a "$LOG_FILE"
        echo "--- New Content Preview ---" | tee -a "$LOG_FILE"
        tail -n 50 "$CONVERSATION_FILE" | tee -a "$LOG_FILE"
        echo "--- End Preview ---" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"

        # Update last known hash
        echo "$REMOTE_HASH" > "$LAST_HASH_FILE"

        # Notify (you can add desktop notification here if needed)
        echo "✅ Response pulled and ready for review" | tee -a "$LOG_FILE"
        echo "---" | tee -a "$LOG_FILE"
    else
        # Quiet check - only log timestamp occasionally
        if (( $(date +%s) % 300 == 0 )); then  # Log every 5 minutes
            echo "⏳ Still monitoring... ($(date +%H:%M:%S))" >> "$LOG_FILE"
        fi
    fi

    sleep "$INTERVAL"
done
