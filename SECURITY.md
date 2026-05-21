# Security Policy

## Supply Chain Security

xcparse takes supply chain security seriously. The following measures are in place to protect users who install xcparse via package managers such as [Mint](https://github.com/yonaskolb/Mint) or [Homebrew](https://brew.sh).

### Immutable Releases

This repository has **Immutable Releases** enabled in GitHub repository settings. This prevents tag retargeting attacks where a malicious actor could point an existing release tag to different (potentially compromised) code.

With immutable releases:
- Once a tag is created for a release, it **cannot** be moved to a different commit.
- Users installing a specific version (e.g., `mint run ChargePoint/xcparse@2.3.2`) are guaranteed to receive the code that was originally tagged.
- This protects against supply chain attacks that attempt to silently replace released code.

### Release Checksums

Every release includes a `checksums.txt` file containing SHA-256 hashes of all release artifacts. Users and CI systems can verify download integrity:

```bash
# After downloading a release artifact
shasum -a 256 -c checksums.txt
```

### Automated Release Process

Releases are created automatically via GitHub Actions when a version tag is pushed. The workflow:

1. Builds the project from the tagged commit
2. Generates SHA-256 checksums for all artifacts
3. Creates a GitHub Release with the artifacts and checksums
4. Uses GitHub's built-in `GITHUB_TOKEN` (no external secrets required)

The release workflow is defined in [`.github/workflows/release.yml`](.github/workflows/release.yml).

### For Repository Administrators

To fully enable immutable releases:

1. Go to **Settings** → **General** → **Tags** in the GitHub repository
2. Under **Tag protection rules**, add a rule to protect version tags (e.g., `[0-9]*`)
3. Go to **Settings** → **General** and enable **Immutable releases** (if available in your plan)

These settings prevent anyone from deleting or force-pushing over existing release tags.

## Reporting a Vulnerability

If you discover a security vulnerability in xcparse, please report it responsibly:

1. **Do NOT** open a public GitHub issue for security vulnerabilities.
2. Email the maintainers directly or use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability) feature.
3. Include a description of the vulnerability, steps to reproduce, and potential impact.

We aim to acknowledge reports within 48 hours and will work with reporters to coordinate disclosure.

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 2.x     | ✓ Active support   |
| 1.x     | Security fixes only|
| < 1.0   | No longer supported|
