# gh-actions

This repo contains reusable workflows so they don't need to be defined in several repos.

## add-issues-to-project.yaml

This reusable Github Action adds an issue from a given repo into a Github Project.

Example usage:

```yaml
on:
  issues:
    types:
      - opened

name: Add opened issue to project
jobs:
  add-issue-to-project:
    uses: Notifycal/gh-actions/.github/workflows/add-issue-to-project.reuse.yaml@<version>
    with:
      issue-node-id: ${{ github.event.issue.node_id }}
    secrets:
      NOTIFYCAL_CICD_APP_ID: ${{ secrets.NOTIFYCAL_CICD_APP_ID }}
      NOTIFYCAL_CICD_APP_SECRET: ${{ secrets.NOTIFYCAL_CICD_APP_SECRET }}

```

## npm-audit.yaml

This reusable Github Action adds an issue from a given repo into a Github Project.

Example usage:

```yaml
on:
  schedule:
    - cron: '0 9 * * 1'
  workflow_dispatch:

name: Security Monitoring
jobs:
  npm-audit:
    name: NPM Audit Check
    uses: Notifycal/gh-actions/.github/workflows/npm-audit.reuse.yaml@<version>
    with:
      repository: ${{ github.repository }}
      ref_name: ${{ github.ref_name }}
      run_link: 'https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}'
      include_dev: true
    secrets:
      SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}

```

## actionlint.yaml

This reusable action lints Github actions.

Example usage: TODO
