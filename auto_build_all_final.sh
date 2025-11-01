#!/bin/bash
set -e

WORKFLOW="auto-release.yml"
BRANCH="main"

echo "[🚀] Starting full automation..."

# Make sure we are on the main branch
git checkout $BRANCH
git pull origin $BRANCH

# Commit any local changes (none expected)
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Auto-commit before workflow"
fi

# Push changes
git push origin $BRANCH

echo "[⚙️] Triggering GitHub Actions workflow ($WORKFLOW)..."

# Trigger the workflow_dispatch for the new workflow only
RUN_ID=$(gh workflow run "$WORKFLOW" --ref "$BRANCH" --json number -q '.number')
echo "Workflow dispatched, run number: $RUN_ID"

# Wait for workflow to finish
while true; do
    STATUS=$(gh run view $RUN_ID --json status,conclusion -q '.status + " " + (.conclusion // "")')
    echo "[...] Workflow status: $STATUS"
    if [[ $STATUS == "completed "* ]]; then
        CONCLUSION=$(echo $STATUS | awk '{print $2}')
        if [[ $CONCLUSION == "success" ]]; then
            echo "[✔] Workflow completed successfully!"
        else
            echo "[❌] Workflow failed with conclusion: $CONCLUSION"
            echo "[📄] Showing logs..."
            gh run view $RUN_ID --log
        fi
        break
    fi
    sleep 10
done

echo "[🎉] Automation complete! APKs should be available in Releases."
