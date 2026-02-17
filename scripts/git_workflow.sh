#!/bin/bash
# Standardized git workflow for all agents
# Usage: ./git_workflow.sh [pull|commit|push|sync] "commit message"
# Example:
#   ./git_workflow.sh pull
#   ./git_workflow.sh commit "Researcher: Initial PA+SR research complete"
#   ./git_workflow.sh sync "PM: Implementation plan v1 ready for review"

set -e

OPERATION="$1"
COMMIT_MSG="$2"

PROJECT_ROOT="/Volumes/Data/Git/EA-OAT-v2"
cd "$PROJECT_ROOT"

echo "=== Git Workflow Helper ==="
echo "Operation: $OPERATION"
echo ""

case "$OPERATION" in
    pull)
        echo "[1/1] Pulling latest changes..."
        git pull origin main
        echo ""
        echo "✅ Done. You now have latest brain/ and experience/"
        ;;

    commit)
        if [ -z "$COMMIT_MSG" ]; then
            echo "ERROR: Commit message required"
            echo "Usage: ./git_workflow.sh commit \"Your message\""
            exit 1
        fi

        echo "[1/3] Staging changes..."
        git add .

        echo "[2/3] Creating commit..."
        git commit -m "$COMMIT_MSG

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

        echo "[3/3] Showing commit..."
        git log -1 --oneline
        echo ""
        echo "✅ Committed. Use './git_workflow.sh push' to push to remote."
        ;;

    push)
        echo "[1/1] Pushing to remote..."
        git push origin main
        echo ""
        echo "✅ Done. Changes now visible to all agents."
        ;;

    sync)
        # Full workflow: pull → commit → push
        if [ -z "$COMMIT_MSG" ]; then
            echo "ERROR: Commit message required for sync"
            echo "Usage: ./git_workflow.sh sync \"Your message\""
            exit 1
        fi

        echo "[1/5] Pulling latest..."
        git pull origin main || {
            echo ""
            echo "⚠️  Pull failed (conflicts?)"
            echo "Resolve conflicts manually, then run:"
            echo "  git add ."
            echo "  ./git_workflow.sh commit \"$COMMIT_MSG\""
            echo "  ./git_workflow.sh push"
            exit 1
        }

        echo "[2/5] Staging changes..."
        git add .

        echo "[3/5] Creating commit..."
        git commit -m "$COMMIT_MSG

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>" || {
            echo ""
            echo "⚠️  Nothing to commit (no changes)"
            exit 0
        }

        echo "[4/5] Pushing to remote..."
        git push origin main

        echo "[5/5] Showing final status..."
        git log -1 --oneline
        echo ""
        echo "✅ Full sync complete."
        ;;

    status)
        echo "Current status:"
        echo ""
        git status
        echo ""
        echo "Recent commits:"
        git log -5 --oneline
        ;;

    *)
        echo "ERROR: Unknown operation: $OPERATION"
        echo ""
        echo "Usage:"
        echo "  ./git_workflow.sh pull"
        echo "  ./git_workflow.sh commit \"message\""
        echo "  ./git_workflow.sh push"
        echo "  ./git_workflow.sh sync \"message\"    (pull + commit + push)"
        echo "  ./git_workflow.sh status"
        exit 1
        ;;
esac
