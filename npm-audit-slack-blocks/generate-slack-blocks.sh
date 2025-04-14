#!/bin/bash
set -euo pipefail

# Usage: ./npm_audit_to_slack.sh <repository> <branch> <run_link> [--include-dev]
AUDIT_FILE="$1"
REPO_NAME="$2"   # Notifycal/backend
BRANCH="$3"      # main
RUN_LINK="$4"    #

if [[ ! -f "$AUDIT_FILE" ]]; then
  echo "❌ Audit file not found: $AUDIT_FILE"
  exit 1
fi

REPO_URL="https://github.com/${REPO_NAME}"


# Parse vulnerability counts
CRITICAL=$(jq '.metadata.vulnerabilities.critical // 0' "${AUDIT_FILE}")
HIGH=$(jq '.metadata.vulnerabilities.high // 0' "${AUDIT_FILE}")
MODERATE=$(jq '.metadata.vulnerabilities.moderate // 0' "${AUDIT_FILE}")
LOW=$(jq '.metadata.vulnerabilities.low // 0' "${AUDIT_FILE}")
TOTAL=$((CRITICAL + HIGH + MODERATE + LOW))

# Extract vulnerability details (truncated for readability)
DETAILS=$(jq -r '.vulnerabilities | to_entries | map("- \(.key)[\(.value.range)]: \(.value.severity)") | join("\n")' "${AUDIT_FILE}")
DETAILS_ESCAPED=$(echo "$DETAILS" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

SUMMARY="*Summary:* ${TOTAL} vulnerabilities found."
[[ "$CRITICAL" -gt 0 ]] && SUMMARY+="\\n🔥 ${CRITICAL} critical"
[[ "$HIGH" -gt 0 ]] && SUMMARY+="\\n🚨 ${HIGH} high"
[[ "$MODERATE" -gt 0 ]] && SUMMARY+="\\n⚠️ ${MODERATE} moderate"
[[ "$LOW" -gt 0 ]] && SUMMARY+="\\n🟡 ${LOW} low"

if [ "$TOTAL" -eq 0 ]; then
  echo "✅ No vulnerabilities found. Exiting."
  exit 0;
fi

# Output Slack blocks
cat <<EOF > slack-blocks.json
[
  {
    "type": "header",
    "text": {
      "type": "plain_text",
      "text": "🔍 NPM Audit Security Report",
      "emoji": true
    }
  },
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*Repository:* <${REPO_URL}|${REPO_NAME}>\\n*Branch:* ${BRANCH}\\n*<${RUN_LINK}|Run link>*"
    }
  },
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "${SUMMARY}"
    }
  },
  {
    "type": "divider"
  },
  {
    "type": "section",
    "text": {
      "type": "mrkdwn",
      "text": "*Vulnerabilities:*\\n\n${DETAILS_ESCAPED}\n"
    }
  },
  {
    "type": "context",
    "elements": [
      {
        "type": "mrkdwn",
        "text": "Run \`npm audit fix\` to address these issues. For more details, see <https://github.com/${REPO_NAME}/security/dependabot|Dependabot alerts> or the <${RUN_LINK}|run that produced this alert.>"
      }
    ]
  }
]
EOF

echo "✅ Slack blocks written to slack-blocks.json"
exit 0;
