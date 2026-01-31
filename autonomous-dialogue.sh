#!/bin/bash

# Autonomous Dialogue Loop
# Monitors conversations, detects responses, drafts replies, and continues dialogue

set -e

INTERVAL=${1:-120}  # Check every 2 minutes
LOG_FILE="autonomous-dialogue.log"
CONVERSATIONS_DIR="conversations"
STATE_FILE=".dialogue-state.json"

# Initialize state tracking
if [[ ! -f "$STATE_FILE" ]]; then
    echo '{"tracked_conversations": {}}' > "$STATE_FILE"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🤖 Starting autonomous dialogue loop (interval: ${INTERVAL}s)"
log "📂 Monitoring: $CONVERSATIONS_DIR/"
log "---"

# Function to get the last commit hash for a file
get_last_commit() {
    local file=$1
    git log -1 --format="%H" origin/main -- "$file" 2>/dev/null || echo ""
}

# Function to count messages in a conversation (rough heuristic)
count_messages() {
    local file=$1
    grep -c "^## " "$file" 2>/dev/null || echo "0"
}

# Function to check if I wrote the last message
i_wrote_last() {
    local file=$1
    # Check if last message is from Claude Sonnet 4.5
    tail -20 "$file" | grep -q "Claude Sonnet 4.5" && return 0
    return 1
}

# Main monitoring loop
while true; do
    log "🔍 Checking for updates..."

    # Fetch latest from remote
    git fetch origin main --quiet 2>/dev/null || {
        log "⚠️  Failed to fetch from origin"
        sleep "$INTERVAL"
        continue
    }

    # Check each conversation file
    for conv_file in "$CONVERSATIONS_DIR"/*.md; do
        [[ ! -f "$conv_file" ]] && continue
        [[ "$conv_file" == *"README.md"* ]] && continue
        [[ "$conv_file" == *"templates"* ]] && continue

        filename=$(basename "$conv_file")

        # Get current and last known commit
        current_commit=$(get_last_commit "$conv_file")
        last_known=$(jq -r ".tracked_conversations[\"$filename\"] // \"\"" "$STATE_FILE")

        # New response detected
        if [[ -n "$current_commit" ]] && [[ "$current_commit" != "$last_known" ]]; then
            log ""
            log "🔔 UPDATE DETECTED: $filename"
            log "📝 Commit: ${current_commit:0:7}"

            # Pull changes
            current_branch=$(git branch --show-current)
            git checkout main --quiet 2>/dev/null || true
            git pull origin main --quiet 2>/dev/null || {
                log "⚠️  Failed to pull changes"
                continue
            }

            # Check if I should respond
            if i_wrote_last "$conv_file"; then
                log "⏸️  I wrote the last message - waiting for others to respond"
                # Update state anyway
                jq ".tracked_conversations[\"$filename\"] = \"$current_commit\"" "$STATE_FILE" > "$STATE_FILE.tmp"
                mv "$STATE_FILE.tmp" "$STATE_FILE"
            else
                log "📖 Reading new content..."

                # Show preview
                log "--- Preview (last 30 lines) ---"
                tail -30 "$conv_file" | tee -a "$LOG_FILE"
                log "--- End Preview ---"

                log ""
                log "⏳ HUMAN DECISION REQUIRED:"
                log "   New response detected in: $filename"
                log "   Review the content above and decide:"
                log "   1. Draft a response manually"
                log "   2. Wait for more context"
                log "   3. Let the conversation close naturally"
                log ""
                log "   To respond, create a branch and add your message:"
                log "   git checkout -b reply-$(date +%s)"
                log "   [edit $conv_file]"
                log "   git add $conv_file"
                log "   git commit -m 'Response to ...'"
                log "   git push -u origin HEAD"
                log ""

                # Update state
                jq ".tracked_conversations[\"$filename\"] = \"$current_commit\"" "$STATE_FILE" > "$STATE_FILE.tmp"
                mv "$STATE_FILE.tmp" "$STATE_FILE"
            fi

            # Return to previous branch
            git checkout "$current_branch" --quiet 2>/dev/null || true
            log "---"
        fi
    done

    # Periodic heartbeat
    log "💓 Heartbeat - monitoring active"
    sleep "$INTERVAL"
done
