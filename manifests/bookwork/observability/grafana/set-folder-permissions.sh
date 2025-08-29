#!/bin/bash

# Script to set folder permissions for Bookwork Dashboards after Grafana restart
# This ensures GitHub OAuth users with Viewer role can access all dashboards

set -e

GRAFANA_URL="http://localhost:3000"
FOLDER_NAME="Bookwork Dashboards"

# Get admin credentials from environment
ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD}"

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: GRAFANA_ADMIN_PASSWORD environment variable not set"
    exit 1
fi

echo "Checking for '$FOLDER_NAME' folder..."

# Get folder UID
FOLDER_UID=$(curl -s -u "$ADMIN_USER:$ADMIN_PASSWORD" "$GRAFANA_URL/api/folders" | \
    jq -r ".[] | select(.title == \"$FOLDER_NAME\") | .uid")

if [ -z "$FOLDER_UID" ] || [ "$FOLDER_UID" = "null" ]; then
    echo "Error: Folder '$FOLDER_NAME' not found"
    exit 1
fi

echo "Found folder '$FOLDER_NAME' with UID: $FOLDER_UID"

# Check current permissions
echo "Checking current permissions..."
CURRENT_PERMS=$(curl -s -u "$ADMIN_USER:$ADMIN_PASSWORD" \
    "$GRAFANA_URL/api/folders/$FOLDER_UID/permissions")

# Check if Viewer role already has permissions
HAS_VIEWER_PERM=$(echo "$CURRENT_PERMS" | jq -r '.[] | select(.role == "Viewer") | .permission')

if [ "$HAS_VIEWER_PERM" = "1" ]; then
    echo "Viewer permissions already set correctly"
    exit 0
fi

echo "Setting Viewer permissions on folder..."

# Set Viewer role permissions (permission 1 = View)
RESPONSE=$(curl -s -u "$ADMIN_USER:$ADMIN_PASSWORD" \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"items":[{"role":"Viewer","permission":1}]}' \
    "$GRAFANA_URL/api/folders/$FOLDER_UID/permissions")

if echo "$RESPONSE" | grep -q "Folder permissions updated"; then
    echo "✅ Successfully set Viewer permissions on '$FOLDER_NAME' folder"
    echo "GitHub OAuth users with Viewer role can now access all dashboards"
else
    echo "❌ Failed to set permissions: $RESPONSE"
    exit 1
fi
