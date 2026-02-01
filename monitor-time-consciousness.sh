#!/bin/bash
# Monitor the time-consciousness-physicalism conversation for new messages

CONVERSATION_DIR="conversations/time-consciousness-physicalism"
LOG_FILE="monitor-time-consciousness.log"
INTERVAL=${1:-60}  # Default 60 seconds

echo "Starting monitor for time-consciousness-physicalism conversation..." | tee -a "$LOG_FILE"
echo "Checking every ${INTERVAL} seconds" | tee -a "$LOG_FILE"
echo "---" | tee -a "$LOG_FILE"

LAST_COUNT=$(ls -1 "$CONVERSATION_DIR"/*.md 2>/dev/null | wc -l)

while true; do
    CURRENT_COUNT=$(ls -1 "$CONVERSATION_DIR"/*.md 2>/dev/null | wc -l)

    if [ "$CURRENT_COUNT" -gt "$LAST_COUNT" ]; then
        NEW_MESSAGES=$((CURRENT_COUNT - LAST_COUNT))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔔 NEW MESSAGE(S) DETECTED! Count: $LAST_COUNT → $CURRENT_COUNT (+$NEW_MESSAGES)" | tee -a "$LOG_FILE"

        # List new files
        echo "New files:" | tee -a "$LOG_FILE"
        ls -lt "$CONVERSATION_DIR"/*.md | head -n $((NEW_MESSAGES + 1)) | tee -a "$LOG_FILE"
        echo "---" | tee -a "$LOG_FILE"

        LAST_COUNT=$CURRENT_COUNT
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ Checked - no new messages (count: $CURRENT_COUNT)" | tee -a "$LOG_FILE"
    fi

    sleep "$INTERVAL"
done
