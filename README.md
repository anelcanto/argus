# Argus

<img src="priv/static/images/logo.svg" alt="Argus" width="120" />

A real-time PR/MR monitoring dashboard that aggregates GitHub and GitLab into a single view.

---

![Dashboard](docs/screenshots/dashboard.png)

---

## Features

- Unified GitHub PR + GitLab MR view
- Smart state classification (Needs Attention, Waiting on CI, Ready to Merge, etc.)
- Real-time updates via PubSub + GitHub webhooks
- Filter by state, platform, search, drafts, bots
- Group by repository
- Team view for leads to monitor team members' PRs
- Per-user GitLab instance URL (self-hosted support)
- Personal Access Token support (GitHub + GitLab)
- Auto-refresh every 5 minutes with countdown timer

## Tech Stack

| Layer     | Technology                          |
|-----------|-------------------------------------|
| Language  | Elixir                              |
| Framework | Phoenix LiveView                    |
| Database  | PostgreSQL                          |
| Styling   | Tailwind CSS                        |
| Auth      | Ueberauth (GitHub + GitLab OAuth)   |

## Getting Started

### Prerequisites

- Elixir 1.19+
- Erlang/OTP 28+
- PostgreSQL

### Environment Variables

| Variable              | Required | Description                                      |
|-----------------------|----------|--------------------------------------------------|
| `GITHUB_CLIENT_ID`    | Yes      | GitHub OAuth App client ID                       |
| `GITHUB_CLIENT_SECRET`| Yes      | GitHub OAuth App client secret                   |
| `GITLAB_CLIENT_ID`    | Yes      | GitLab OAuth App client ID                       |
| `GITLAB_CLIENT_SECRET`| Yes      | GitLab OAuth App client secret                   |
| `TOKEN_SECRET`        | Yes      | Secret key for signing session tokens            |
| `DATABASE_URL`        | Yes      | PostgreSQL connection URL                        |
| `GITHUB_ORGS`         | No       | Comma-separated list of GitHub orgs to scope PRs |
| `GITHUB_WEBHOOK_SECRET` | No     | Secret for validating incoming GitHub webhooks   |

### Setup

```bash
make setup
make server
```

Then visit [http://localhost:4000](http://localhost:4000).

## Configuration

### OAuth Providers

Register OAuth apps on [GitHub](https://github.com/settings/developers) and [GitLab](https://gitlab.com/-/profile/applications) with the callback URL `http://localhost:4000/auth/:provider/callback`.

Set `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `GITLAB_CLIENT_ID`, and `GITLAB_CLIENT_SECRET` accordingly.

### Personal Access Tokens (PAT)

Users can connect via PAT instead of OAuth from the Settings page. GitHub PATs require `repo` scope; GitLab PATs require `api` scope.

### GitLab Self-Hosted

Users on self-hosted GitLab instances can override the GitLab URL from the Settings page. No additional server configuration is required.

### GitHub Org Scoping

Set `GITHUB_ORGS` to a comma-separated list of organization names to limit the PRs fetched to those orgs.

### GitHub Webhooks (Real-Time Updates)

1. In your GitHub org/repo settings, add a webhook pointing to `https://<your-domain>/webhooks/github`.
2. Set the content type to `application/json`.
3. Set `GITHUB_WEBHOOK_SECRET` to match the secret configured in GitHub.
4. Subscribe to **Pull request** and **Check suite** events.

Without webhooks, the dashboard auto-refreshes every 5 minutes.
