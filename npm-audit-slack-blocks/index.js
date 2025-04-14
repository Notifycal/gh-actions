import * as core from '@actions/core';
import { readFile, writeFile } from 'fs/promises';

try {
  const auditFile = core.getInput('audit_file');
  const repo = core.getInput('repository');
  const branch = core.getInput('branch');
  const runLink = core.getInput('run_link');

  const auditJson = JSON.parse(await readFile(auditFile, 'utf8'));
  const { vulnerabilities = {}, metadata = {} } = auditJson;
  const { critical = 0, high = 0, moderate = 0, low = 0 } = metadata.vulnerabilities || {};
  const total = critical + high + moderate + low;

  if (total === 0) {
    core.info("✅ No vulnerabilities found. No Slack message generated.");
    return;
  }

  let summary = `*Summary:* ${total} vulnerabilities found.`;
  if (critical) summary += `\n🔥 ${critical} critical`;
  if (high)     summary += `\n🚨 ${high} high`;
  if (moderate) summary += `\n⚠️ ${moderate} moderate`;
  if (low)      summary += `\n🟡 ${low} low`;

  const details = Object.entries(vulnerabilities)
    .map(([pkg, vuln]) => `- ${pkg}[${vuln.range}]: ${vuln.severity}`)
    .join('\n');

  const blocks = [
    {
      type: 'header',
      text: { type: 'plain_text', text: '🔍 NPM Audit Security Report', emoji: true }
    },
    {
      type: 'section',
      text: { type: 'mrkdwn', text: `*Repository:* <https://github.com/${repo}|${repo}>\n*Branch:* ${branch}\n*<${runLink}|Run link>*` }
    },
    {
      type: 'section',
      text: { type: 'mrkdwn', text: summary }
    },
    { type: 'divider' },
    {
      type: 'section',
      text: { type: 'mrkdwn', text: `*Vulnerabilities:*\n\`\`\`${details}\`\`\`` }
    },
    {
      type: 'context',
      elements: [
        {
          type: 'mrkdwn',
          text: `Run \`npm audit fix\`. See <https://github.com/${repo}/security/dependabot|Dependabot alerts> or <${runLink}|run>.`
        }
      ]
    }
  ];

  await writeFile('slack-blocks.json', JSON.stringify(payload, null, 2));
  core.setOutput('blocks_file', 'slack-blocks.json');
  core.info('✅ Slack blocks generated: slack-blocks.json');

} catch (err) {
  core.setFailed(err.message);
}
