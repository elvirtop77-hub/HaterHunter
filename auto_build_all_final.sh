0#!/bin/bash
set -e

WORKFLOW="auto-release.yml"
BRANCH="main"
ARTIFACT_DIR="artifacts"

echo "[🚀] Starting full automation..."

# Ensure main branch
git checkout $BRANCH
git pull origin $BRANCH

# Auto-commit any local changes
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Auto-commit before workflow"
fi

# Push changes
git push origin $BRANCH

echo "[⚙️] Triggering GitHub Actions workflow ($WORKFLOW)..."

# Trigger workflow_dispatch
gh workflow run "$WORKFLOW" --ref "$BRANCH"
echo "[ℹ️] Workflow dispatched, waiting for it to appear in run list..."

# Get latest run databaseId for this workflow
RUN_ID=$(gh run list --workflow="$WORKFLOW" --branch="$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId')
echo "Workflow run databaseId: $RUN_ID"

# Wait for workflow completion
while true; do
    STATUS=$(gh run view "$RUN_ID" --json status,conclusion -q '.status + " " + (.conclusion // "")')
    echo "[...] Workflow status: $STATUS"
    if [[ $STATUS == "completed "* ]]; then
        CONCLUSION=$(echo $STATUS | awk '{print $2}')
        if [[ $CONCLUSION == "success" ]]; then
            echo "[✔] Workflow completed successfully!"
        else
            echo "[❌] Workflow failed with conclusion: $CONCLUSION"
            echo "[📄] Showing full logs..."
            gh run view "$RUN_ID" --log
            exit 1
        fi
        break
    fi
    sleep 10
done

# Create artifacts folder
mkdir -p "$ARTIFACT_DIR"

echo "[⬇️] Downloading artifacts..."
# Get list of artifact names
ARTIFACTS=$(gh run view "$RUN_ID" --json artifacts -q '.artifacts[].name')

for ART in $ARTIFACTS; do
    echo "[⬇️] Downloading $ART..."
    gh run download "$RUN_ID" -n "$ART" -D "$ARTIFACT_DIR"
done

echo "[🎉] Automation complete! APKs downloaded to $ARTIFACT_DIR/"
