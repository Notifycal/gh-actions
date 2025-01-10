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
    uses: Notifycal/gh-actions/.github/workflows/add-issue-to-project.yaml@main
    with:
      issue-node-id: ${{ github.event.issue.node_id }}
    secrets:
      NOTIFYCAL_CICD_APP_ID: ${{ secrets.NOTIFYCAL_CICD_APP_ID }}
      NOTIFYCAL_CICD_APP_SECRET: ${{ secrets.NOTIFYCAL_CICD_APP_SECRET }}

```
