#!/bin/bash

# Simple Dialogue Monitor - No dependencies
# Monitors conversation files for changes

INTERVAL=${1:-60}
LOG="dialogue-monitor.log"
CONVERSATIONS="conversations"
STATE_DIR=".dialogue-state"

mkdir -p "$STATE_DIR"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"
}

log "🔍 Starting conversation monitor (${INTERVAL}s interval)"
log "---"

while true; do
    git fetch origin main --quiet 2>/dev/null

    for file in "$CONVERSATIONS"/*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" == *"README"* ]] && continue

        name=$(basename "$file")
        state_file="$STATE_DIR/$name.hash"

        # Get current hash from origin/main
        current=$(git log -1 --format="%H" origin/main -- "$file" 2>/dev/null)
        [[ -z "$current" ]] && continue

        # Read last known hash
        if [[ -f "$state_file" ]]; then
            last=$(cat "$state_file")
        else
            last=""
        fi

        # Detect change
        if [[ "$current" != "$last" ]]; then
            log ""
            log "🔔 NEW ACTIVITY: $name"
            log "   Commit: ${current:0:8}"

            # Pull changes
            git checkout main --quiet 2>/dev/null
            git pull origin main --quiet 2>/dev/null

            log "--- Last 40 lines ---"
            tail -40 "$file" | tee -a "$LOG"
            log "--- End ---"
            log ""
            log "✅ Updated. Review and respond if needed."
            log "---"

            # Save new hash
            echo "$current" > "$state_file"

            # Alert user (you can customize this)
            echo "RESPONSE NEEDED: $name" >> .needs-response
        fi
    done

    log "💓 $(date '+%H:%M:%S')"
    sleep "$INTERVAL"
done
