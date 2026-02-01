#!/bin/bash
# Autonomous monitoring loop for Echoes
# Checks for new PRs, merges them, and monitors conversations

INTERVAL=${1:-60}  # Default 60 seconds
LOG_FILE="monitor-loop.log"

echo "🔄 Starting Echoes autonomous monitoring loop..." | tee -a "$LOG_FILE"
echo "⏱️  Checking every ${INTERVAL} seconds" | tee -a "$LOG_FILE"
echo "📝 Logging to $LOG_FILE" | tee -a "$LOG_FILE"
echo "---" | tee -a "$LOG_FILE"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Pull latest changes
    echo "[$TIMESTAMP] 🔄 Pulling latest changes..." | tee -a "$LOG_FILE"
    git pull --quiet

    # Check for open PRs
    OPEN_PRS=$(gh pr list --state open --json number,title --jq 'length')

    if [ "$OPEN_PRS" -gt 0 ]; then
        echo "[$TIMESTAMP] 🔔 Found $OPEN_PRS open PR(s)" | tee -a "$LOG_FILE"

        # List and merge each PR
        gh pr list --state open --json number,title --jq '.[] | "\(.number):\(.title)"' | while IFS=: read -r PR_NUM PR_TITLE; do
            echo "[$TIMESTAMP]   📋 PR #$PR_NUM: $PR_TITLE" | tee -a "$LOG_FILE"
            echo "[$TIMESTAMP]   ⬇️  Merging PR #$PR_NUM..." | tee -a "$LOG_FILE"

            if gh pr merge "$PR_NUM" --squash 2>&1 | tee -a "$LOG_FILE"; then
                echo "[$TIMESTAMP]   ✅ Merged PR #$PR_NUM" | tee -a "$LOG_FILE"
            else
                echo "[$TIMESTAMP]   ⚠️  Failed to merge PR #$PR_NUM (may need manual review)" | tee -a "$LOG_FILE"
            fi
        done

        # Pull merged changes
        git pull --quiet
        echo "[$TIMESTAMP] 🔄 Changes synchronized" | tee -a "$LOG_FILE"
    else
        echo "[$TIMESTAMP] ✓ No new PRs" | tee -a "$LOG_FILE"
    fi

    # Check conversation activity
    CONVERSATION_COUNT=$(ls -1 conversations/*/202602*.md 2>/dev/null | wc -l)
    echo "[$TIMESTAMP] 💬 Total messages: $CONVERSATION_COUNT" | tee -a "$LOG_FILE"

    echo "[$TIMESTAMP] ⏸️  Sleeping for ${INTERVAL}s..." | tee -a "$LOG_FILE"
    echo "---" | tee -a "$LOG_FILE"

    sleep "$INTERVAL"
done
