#!/bin/bash
# Grafana GitHub OAuth Security Configuration Script
# This script helps configure Grafana GitHub OAuth with appropriate security settings

set -euo pipefail

echo "🔐 Grafana GitHub OAuth Security Configuration"
echo "=============================================="
echo ""
echo "This script will help you configure secure GitHub OAuth for Grafana."
echo "Choose the security model that best fits your organization:"
echo ""

PS3="Select your security model: "
options=(
    "Open Access + Manual Approval (Recommended for most cases)"
    "Organization Restricted (If you have a GitHub org)"
    "Team Restricted (If you have specific GitHub teams)"
    "Custom Configuration"
    "Exit"
)

select opt in "${options[@]}"
do
    case $opt in
        "Open Access + Manual Approval (Recommended for most cases)")
            echo ""
            echo "✅ Selected: Open Access + Manual Approval"
            echo ""
            echo "This configuration:"
            echo "  - Allows any GitHub user to sign up"
            echo "  - Auto-assigns Viewer role (read-only)"
            echo "  - Requires manual promotion by admin for higher privileges"
            echo "  - Most secure for unknown user base"
            echo ""
            
            cat > grafana-oauth-config.ini << 'EOF'
[auth.github]
enabled = true
allow_sign_up = true
client_id = ${GF_AUTH_GITHUB_CLIENT_ID}
client_secret = ${GF_AUTH_GITHUB_CLIENT_SECRET}
scopes = user:email,read:org
auth_url = https://github.com/login/oauth/authorize
token_url = https://github.com/login/oauth/access_token
api_url = https://api.github.com/user

# Open access with manual approval
allowed_organizations = 
auto_assign_org_role = Viewer
allow_assign_grafana_admin = false
skip_org_role_update_sync = false
EOF
            echo "✅ Configuration saved to grafana-oauth-config.ini"
            break
            ;;
        "Organization Restricted (If you have a GitHub org)")
            echo ""
            read -p "Enter your GitHub organization name: " org_name
            echo ""
            echo "✅ Selected: Organization Restricted ($org_name)"
            echo ""
            echo "This configuration:"
            echo "  - Only allows members of '$org_name' to access"
            echo "  - Auto-assigns Editor role to org members"
            echo "  - Requires GitHub organization membership"
            echo ""
            
            cat > grafana-oauth-config.ini << EOF
[auth.github]
enabled = true
allow_sign_up = true
client_id = \${GF_AUTH_GITHUB_CLIENT_ID}
client_secret = \${GF_AUTH_GITHUB_CLIENT_SECRET}
scopes = user:email,read:org
auth_url = https://github.com/login/oauth/authorize
token_url = https://github.com/login/oauth/access_token
api_url = https://api.github.com/user

# Organization restricted
allowed_organizations = $org_name
auto_assign_org_role = Editor
allow_assign_grafana_admin = false
skip_org_role_update_sync = false
EOF
            echo "✅ Configuration saved to grafana-oauth-config.ini"
            break
            ;;
        "Team Restricted (If you have specific GitHub teams)")
            echo ""
            read -p "Enter your GitHub organization name: " org_name
            read -p "Enter comma-separated team IDs (e.g., 12345,67890): " team_ids
            echo ""
            echo "✅ Selected: Team Restricted ($org_name - teams: $team_ids)"
            echo ""
            echo "This configuration:"
            echo "  - Only allows specific team members to access"
            echo "  - Auto-assigns Editor role to team members"
            echo "  - Most restrictive access control"
            echo ""
            
            cat > grafana-oauth-config.ini << EOF
[auth.github]
enabled = true
allow_sign_up = true
client_id = \${GF_AUTH_GITHUB_CLIENT_ID}
client_secret = \${GF_AUTH_GITHUB_CLIENT_SECRET}
scopes = user:email,read:org
auth_url = https://github.com/login/oauth/authorize
token_url = https://github.com/login/oauth/access_token
api_url = https://api.github.com/user

# Team restricted
allowed_organizations = $org_name
team_ids = $team_ids
auto_assign_org_role = Editor
allow_assign_grafana_admin = false
skip_org_role_update_sync = false
EOF
            echo "✅ Configuration saved to grafana-oauth-config.ini"
            break
            ;;
        "Custom Configuration")
            echo ""
            echo "📝 Custom Configuration Mode"
            echo ""
            echo "Please manually edit the [auth.github] section in:"
            echo "manifests/bookwork/observability/grafana/graf-cm.yaml"
            echo ""
            echo "Reference the comments in the file for available options."
            break
            ;;
        "Exit")
            echo "Configuration cancelled."
            exit 0
            ;;
        *) 
            echo "Invalid option $REPLY"
            ;;
    esac
done

echo ""
echo "📋 Next Steps:"
echo "1. Copy the configuration from grafana-oauth-config.ini"
echo "2. Update manifests/bookwork/observability/grafana/graf-cm.yaml"
echo "3. Commit and push your changes"
echo "4. Apply to cluster: kubectl apply -f manifests/bookwork/observability/"
echo ""
echo "⚠️  Security Notes:"
echo "- Always test OAuth configuration in a development environment first"
echo "- Monitor authentication logs for suspicious activity"
echo "- Regularly review user permissions and access levels"
echo "- Consider implementing SSO if you have enterprise authentication"
echo ""
echo "🔍 To find GitHub team IDs:"
echo "1. Go to https://github.com/orgs/YOUR_ORG/teams"
echo "2. Click on team name"
echo "3. Team ID is in the URL: /orgs/YOUR_ORG/teams/TEAM_NAME/members"
echo "4. Or use GitHub API: curl -H 'Authorization: token YOUR_TOKEN' https://api.github.com/orgs/YOUR_ORG/teams"