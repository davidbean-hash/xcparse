# Releasing xcparse

This document describes how new releases of xcparse are published and how the
Homebrew tap is automatically updated.

## Creating a Release

1. Tag the commit you want to release:

   ```bash
   git tag v2.4.0
   git push origin v2.4.0
   ```

2. Create a GitHub release from the tag (via the GitHub UI or the CLI):

   ```bash
   gh release create v2.4.0 --generate-notes
   ```

3. Publishing the release triggers the **Update Homebrew Tap** workflow, which
   automatically opens a PR to the
   [`homebrew-xcparse`](https://github.com/ChargePoint/homebrew-xcparse) tap
   repository with the new version and SHA256.

## How the Automation Works

The workflow (`.github/workflows/update-homebrew.yml`) runs whenever a GitHub
release is published. It performs the following steps:

1. **Extracts the version** from the release tag (strips a leading `v` if
   present).
2. **Downloads the source tarball** for the release and computes its SHA256
   checksum.
3. **Clones the Homebrew tap repo** (`<owner>/homebrew-xcparse`) using a
   personal access token stored as a repository secret.
4. **Updates (or creates) the formula** (`Formula/xcparse.rb`) with the new
   URL and SHA256.
5. **Pushes a branch** and **opens a pull request** to the tap repository.

Once the PR is reviewed and merged, users running `brew upgrade xcparse` will
receive the new version.

## Setting Up the `HOMEBREW_TAP_TOKEN` Secret

The workflow requires a GitHub personal access token (PAT) with permission to
push branches and create pull requests in the Homebrew tap repository.

### Step 1 — Create the token

1. Go to **GitHub → Settings → Developer settings → Personal access tokens →
   Fine-grained tokens** ([direct link](https://github.com/settings/personal-access-tokens/new)).
2. Give it a descriptive name, e.g. `homebrew-tap-automation`.
3. Set the **Resource owner** to the organization or user that owns the tap
   repo.
4. Under **Repository access**, select **Only select repositories** and choose
   the `homebrew-xcparse` repository.
5. Grant the following **Repository permissions**:
   - **Contents** — Read and write (to push branches)
   - **Pull requests** — Read and write (to open PRs)
6. Click **Generate token** and copy the value.

### Step 2 — Add the secret to the xcparse repo

1. Go to the xcparse repository on GitHub.
2. Navigate to **Settings → Secrets and variables → Actions**.
3. Click **New repository secret**.
4. Set the name to `HOMEBREW_TAP_TOKEN` and paste the token value.
5. Click **Add secret**.

### Step 3 — Ensure the tap repo exists

The workflow expects a repository named `homebrew-xcparse` under the same
GitHub owner as xcparse. If it does not exist yet:

```bash
gh repo create <owner>/homebrew-xcparse --public --description "Homebrew tap for xcparse"
```

The workflow will create the `Formula/xcparse.rb` file automatically on the
first release.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Workflow fails at "Clone Homebrew tap repo" | `HOMEBREW_TAP_TOKEN` is missing or does not have access to the tap repo. |
| "No changes to commit" | The formula already has the correct URL and SHA256 for this release. |
| PR is not created | The tap repo's default branch may not be `main`. Update the `base` field in the workflow. |

## Manual Formula Update

If you need to update the formula without creating a release:

```bash
# Compute the SHA256 of an existing release tarball
curl -fsSL https://github.com/<owner>/xcparse/archive/refs/tags/v2.4.0.tar.gz | sha256sum

# Then edit Formula/xcparse.rb in the homebrew-xcparse repo directly.
```
