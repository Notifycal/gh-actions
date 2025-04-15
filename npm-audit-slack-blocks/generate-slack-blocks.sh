#!/bin/bash
set -euo pipefail

generate_vuln_block() {
  local title="$1"      # Block title
  local raw_details="$2"

  if [[ -n "$raw_details" ]]; then
    local escaped_details
    escaped_details=$(echo -e "$raw_details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    cat <<EOF
,
{
  "type": "section",
  "text": {
    "type": "mrkdwn",
    "text": "*${title}:*\\n\\n\`\`\`${escaped_details}\n\`\`\`"
  }
}
EOF
  fi
}

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

# Extract vulnerability details
DEP_DETAILS=""
DEV_DEP_DETAILS=""

for pkg in $(jq -r '.vulnerabilities | keys[]' "${AUDIT_FILE}"); do
  RANGE=$(jq -r --arg p "$pkg" '.vulnerabilities[$p].range' "${AUDIT_FILE}")
  SEVERITY=$(jq -r --arg p "$pkg" '.vulnerabilities[$p].severity' "${AUDIT_FILE}")

  if jq -e --arg p "$pkg" '.devDependencies[$p]' package.json > /dev/null; then
    DEV_DEP_DETAILS+="- ${pkg}[${RANGE}]: ${SEVERITY}\n"
  else
    DEP_DETAILS+="- ${pkg}[${RANGE}]: ${SEVERITY}\n"
  fi
done


SUMMARY="*Summary:* ${TOTAL} security vulnerabilities found."
[[ "$CRITICAL" -gt 0 ]] && SUMMARY+="\\n🔥 ${CRITICAL} critical"
[[ "$HIGH" -gt 0 ]] && SUMMARY+="\\n🚨 ${HIGH} high"
[[ "$MODERATE" -gt 0 ]] && SUMMARY+="\\n⚠️ ${MODERATE} moderate"
[[ "$LOW" -gt 0 ]] && SUMMARY+="\\n🟡 ${LOW} low"

if [ "$TOTAL" -eq 0 ]; then
  SUMMARY="*Summary:* No security vulnerabilities found."
  cat <<EOF > slack-blocks.json
[
  {
    "type": "header",
    "text": {
      "type": "plain_text",
      "text": "🔍 Vulnerability Report - [${REPO_NAME}] - ${TOTAL} vulnerabilities found",
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
  }
]
EOF
  exit 0;
fi

DEP_BLOCK=$(generate_vuln_block "📦 Vulnerabilities in Dependencies" "$DEP_DETAILS")
DEV_DEP_BLOCK=$(generate_vuln_block "🔧 Vulnerabilities in Dev dependencies" "$DEV_DEP_DETAILS")

# Output Slack blocks
cat <<EOF > slack-blocks.json
[
  {
    "type": "header",
    "text": {
      "type": "plain_text",
      "text": "🔍 Vulnerability Report - [${REPO_NAME}] - ${TOTAL} vulnerabilities found",
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
  }${DEP_BLOCK}${DEV_DEP_BLOCK},
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
