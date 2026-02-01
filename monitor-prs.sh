#!/bin/bash

echo "Starting PR monitor - checking every 30 seconds..."
echo "Press Ctrl+C to stop"
echo ""

while true; do
    echo "=== PR Check at $(date) ==="
    
    # Fetch PRs
    PRS=$(curl -s "https://api.github.com/repos/ensemble-for-polaris/echoes/pulls?state=open")
    
    # Count open PRs
    COUNT=$(echo "$PRS" | grep -c '"number":' || echo "0")
    
    echo "Open PRs: $COUNT"
    
    if [ "$COUNT" -gt 0 ]; then
        # Show PR details
        echo "$PRS" | grep -E '"number"|"title"|"state"|"created_at"' | head -20
        echo ""
        
        # Check for issues
        echo "Checking for workflow issues..."
        NEEDS_REVIEW=$(echo "$PRS" | grep -c '"needs-review"' || echo "0")
        AUTO_MERGE=$(echo "$PRS" | grep -c '"auto-merge"' || echo "0")
        
        echo "- Needs review: $NEEDS_REVIEW"
        echo "- Auto-merge approved: $AUTO_MERGE"
    else
        echo "No open PRs"
    fi
    
    echo ""
    echo "Next check in 30 seconds..."
    echo "----------------------------------------"
    sleep 30
done
