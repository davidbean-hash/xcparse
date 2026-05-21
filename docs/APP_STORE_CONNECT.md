# Deploying Screenshots to App Store Connect with xcparse

This guide covers the complete workflow for extracting screenshots from `.xcresult` bundles using **xcparse** and uploading them to **App Store Connect** via its REST API — no fastlane required.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1: Extract Screenshots with xcparse](#step-1-extract-screenshots-with-xcparse)
  - [Recommended Folder Structure](#recommended-folder-structure)
  - [Filtering Screenshots](#filtering-screenshots)
- [Step 2: Set Up App Store Connect API Credentials](#step-2-set-up-app-store-connect-api-credentials)
  - [Creating an API Key](#creating-an-api-key)
  - [Generating a JWT Token](#generating-a-jwt-token)
- [Step 3: Upload Screenshots via the App Store Connect API](#step-3-upload-screenshots-via-the-app-store-connect-api)
  - [API Workflow Overview](#api-workflow-overview)
  - [Locales and Display Types](#locales-and-display-types)
  - [Step 3a: Look Up Your App and Version](#step-3a-look-up-your-app-and-version)
  - [Step 3b: Get or Create App Store Version Localizations](#step-3b-get-or-create-app-store-version-localizations)
  - [Step 3c: Get or Create Screenshot Sets](#step-3c-get-or-create-screenshot-sets)
  - [Step 3d: Reserve a Screenshot Upload](#step-3d-reserve-a-screenshot-upload)
  - [Step 3e: Upload the Screenshot Binary](#step-3e-upload-the-screenshot-binary)
  - [Step 3f: Commit the Upload](#step-3f-commit-the-upload)
- [Step 4: Complete Automation Script](#step-4-complete-automation-script)
- [Device-to-Display-Type Mapping](#device-to-display-type-mapping)
- [Language-to-Locale Mapping](#language-to-locale-mapping)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Overview

When running UI tests across multiple device simulators and languages, Xcode produces `.xcresult` bundles containing screenshots for every test configuration. **xcparse** can extract these screenshots into an organized folder hierarchy by language, device model, and test plan configuration — exactly the structure needed to batch-upload them to App Store Connect.

The workflow is:

```
Xcode UI Tests → .xcresult bundle → xcparse → organized screenshots → App Store Connect API
```

---

## Prerequisites

- **xcparse** installed ([Installation guide](../README.md#installation))
- **macOS** with Xcode 11+ (for generating `.xcresult` bundles)
- An **Apple Developer account** with Admin or App Manager role
- **curl** and **openssl** (pre-installed on macOS)
- **Python 3** or **Ruby** (for JWT generation) — or use the included helper script
- An `.xcresult` bundle from a UI test run

---

## Step 1: Extract Screenshots with xcparse

### Recommended Folder Structure

For App Store Connect uploads, organize screenshots by **language** and **device model**:

```bash
xcparse screenshots \
  --language \
  --model \
  --test-plan-config \
  --activity-type userCreated \
  /path/to/UITests.xcresult \
  /path/to/output
```

This produces a folder structure like:

```
output/
├── en/
│   ├── iPhone 14 Pro Max/
│   │   ├── screenshot_001.png
│   │   ├── screenshot_002.png
│   │   └── ...
│   ├── iPhone 14 Pro/
│   │   └── ...
│   ├── iPad Pro (12.9-inch) (6th generation)/
│   │   └── ...
│   └── ...
├── ja/
│   ├── iPhone 14 Pro Max/
│   │   └── ...
│   └── ...
├── de/
│   └── ...
└── ...
```

> **Tip:** Use `--activity-type userCreated` to export only screenshots you explicitly captured in your tests (via `XCUIScreenshot`), excluding automatic system screenshots.

### Filtering Screenshots

| Goal | Options |
|------|---------|
| Only user-created screenshots | `--activity-type userCreated` |
| Only from passing tests | `--test-status Success` |
| Only from failing tests | `--test-status Failure` |
| Separate by test plan config | `--test-plan-config` |
| Include region in path | `--region` |

For App Store screenshots, you typically want only `userCreated` screenshots from `Success` tests:

```bash
xcparse screenshots \
  --language \
  --model \
  --activity-type userCreated \
  --test-status Success \
  /path/to/UITests.xcresult \
  /path/to/screenshots
```

---

## Step 2: Set Up App Store Connect API Credentials

### Creating an API Key

1. Go to [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Click the **+** button to create a new key
3. Give it a name (e.g., "Screenshot Uploader")
4. Select the **Admin** or **App Manager** role
5. Click **Generate**
6. **Download the `.p8` private key file** — you can only download it once
7. Note your **Issuer ID** (shown at the top of the page)
8. Note the **Key ID** (shown in the key list)

You will have three values:

| Value | Example | Where to find it |
|-------|---------|-------------------|
| **Issuer ID** | `57246542-96fe-1a63-e053-0824d011072a` | Top of the API Keys page |
| **Key ID** | `2X9R4HXF34` | API key table |
| **Private Key** | `AuthKey_2X9R4HXF34.p8` | Downloaded `.p8` file |

### Generating a JWT Token

The App Store Connect API uses JWT (JSON Web Token) authentication. Here's how to generate a token:

#### Using Python

```python
#!/usr/bin/env python3
"""Generate a JWT for the App Store Connect API."""

import jwt
import time

# Your credentials
ISSUER_ID = "YOUR_ISSUER_ID"
KEY_ID = "YOUR_KEY_ID"
PRIVATE_KEY_PATH = "AuthKey_YOURKEYID.p8"

with open(PRIVATE_KEY_PATH, "r") as f:
    private_key = f.read()

# JWT expires after 20 minutes (max allowed)
payload = {
    "iss": ISSUER_ID,
    "iat": int(time.time()),
    "exp": int(time.time()) + 1200,
    "aud": "appstoreconnect-v1",
}

token = jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})
print(token)
```

Install the dependency: `pip install PyJWT cryptography`

#### Using Ruby

```ruby
#!/usr/bin/env ruby
require "jwt"
require "time"

issuer_id = "YOUR_ISSUER_ID"
key_id = "YOUR_KEY_ID"
private_key = OpenSSL::PKey.read(File.read("AuthKey_YOURKEYID.p8"))

payload = {
  iss: issuer_id,
  iat: Time.now.to_i,
  exp: Time.now.to_i + 1200,
  aud: "appstoreconnect-v1"
}

token = JWT.encode(payload, private_key, "ES256", header_fields = { kid: key_id })
puts token
```

#### Using curl and openssl (shell only)

```bash
#!/bin/bash
# Generate JWT using only shell tools

ISSUER_ID="YOUR_ISSUER_ID"
KEY_ID="YOUR_KEY_ID"
PRIVATE_KEY_PATH="AuthKey_YOURKEYID.p8"

HEADER=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$KEY_ID" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
NOW=$(date +%s)
EXP=$((NOW + 1200))
PAYLOAD=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' "$ISSUER_ID" "$NOW" "$EXP" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

SIGNATURE=$(printf '%s.%s' "$HEADER" "$PAYLOAD" | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

JWT="${HEADER}.${PAYLOAD}.${SIGNATURE}"
echo "$JWT"
```

---

## Step 3: Upload Screenshots via the App Store Connect API

### API Workflow Overview

```
1. Get your app's App Store version
2. Get (or create) version localizations for each language
3. Get (or create) screenshot sets for each display type
4. For each screenshot:
   a. Reserve a screenshot upload (POST)
   b. Upload the binary to Apple's storage (PUT)
   c. Commit the upload (PATCH)
```

All API requests use the base URL: `https://api.appstoreconnect.apple.com/v1`

Include this header on every request:
```
Authorization: Bearer <YOUR_JWT_TOKEN>
Content-Type: application/json
```

### Locales and Display Types

App Store Connect requires screenshots to be organized by **locale** and **display type** (screen size). You must map your xcparse folder names to these identifiers.

### Step 3a: Look Up Your App and Version

```bash
# Find your app
APP_ID="YOUR_APP_ID"  # e.g., 1234567890

# List App Store versions
curl -s \
  -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions?filter[platform]=IOS&filter[appStoreState]=PREPARE_FOR_SUBMISSION" \
  | python3 -m json.tool
```

Save the version ID from the response:
```bash
VERSION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Step 3b: Get or Create App Store Version Localizations

List existing localizations:
```bash
curl -s \
  -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$VERSION_ID/appStoreVersionLocalizations" \
  | python3 -m json.tool
```

Create a new localization if needed:
```bash
curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "appStoreVersionLocalizations",
      "attributes": {
        "locale": "en-US"
      },
      "relationships": {
        "appStoreVersion": {
          "data": {
            "type": "appStoreVersions",
            "id": "'$VERSION_ID'"
          }
        }
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations"
```

### Step 3c: Get or Create Screenshot Sets

Each locale + display type combination requires a **screenshot set**.

List existing screenshot sets for a localization:
```bash
LOCALIZATION_ID="your-localization-id"

curl -s \
  -H "Authorization: Bearer $JWT" \
  "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/$LOCALIZATION_ID/appScreenshotSets" \
  | python3 -m json.tool
```

Create a new screenshot set:
```bash
curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "appScreenshotSets",
      "attributes": {
        "screenshotDisplayType": "APP_IPHONE_67"
      },
      "relationships": {
        "appStoreVersionLocalization": {
          "data": {
            "type": "appStoreVersionLocalizations",
            "id": "'$LOCALIZATION_ID'"
          }
        }
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/appScreenshotSets"
```

### Step 3d: Reserve a Screenshot Upload

```bash
SCREENSHOT_SET_ID="your-screenshot-set-id"
FILE_NAME="screenshot_001.png"
FILE_SIZE=$(stat -f%z "$FILE_NAME" 2>/dev/null || stat -c%s "$FILE_NAME")

curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "appScreenshots",
      "attributes": {
        "fileName": "'$FILE_NAME'",
        "fileSize": '$FILE_SIZE'
      },
      "relationships": {
        "appScreenshotSet": {
          "data": {
            "type": "appScreenshotSets",
            "id": "'$SCREENSHOT_SET_ID'"
          }
        }
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/appScreenshots"
```

The response contains:
- `data.id` — the screenshot ID
- `data.attributes.uploadOperations` — an array of upload operations with URLs, headers, offset, and length

### Step 3e: Upload the Screenshot Binary

The upload operations tell you how to chunk and upload the file. For most screenshots, there is a single operation:

```bash
# From the reservation response:
UPLOAD_URL="https://uploadUrl.from.response"
SCREENSHOT_FILE="screenshot_001.png"

# Upload each chunk (usually just one for screenshots)
curl -X PUT \
  -H "Content-Type: image/png" \
  --data-binary @"$SCREENSHOT_FILE" \
  "$UPLOAD_URL"
```

For multi-part uploads, split the file and upload each part to its respective URL:

```bash
# Example for multi-part (offset and length from uploadOperations)
dd if="$SCREENSHOT_FILE" bs=1 skip=$OFFSET count=$LENGTH 2>/dev/null | \
  curl -X PUT \
    -H "Content-Type: image/png" \
    --data-binary @- \
    "$UPLOAD_URL"
```

### Step 3f: Commit the Upload

After uploading all parts, verify the asset by committing the upload:

```bash
SCREENSHOT_ID="screenshot-id-from-reservation"
SOURCE_MD5=$(md5 -q "$SCREENSHOT_FILE" 2>/dev/null || md5sum "$SCREENSHOT_FILE" | awk '{print $1}')

curl -s -X PATCH \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "type": "appScreenshots",
      "id": "'$SCREENSHOT_ID'",
      "attributes": {
        "sourceFileChecksum": "'$SOURCE_MD5'",
        "uploaded": true
      }
    }
  }' \
  "https://api.appstoreconnect.apple.com/v1/appScreenshots/$SCREENSHOT_ID"
```

---

## Step 4: Complete Automation Script

A complete helper script is provided at [`scripts/xcparse-to-appstore.sh`](../scripts/xcparse-to-appstore.sh).

### Quick Start

```bash
# 1. Extract screenshots from your xcresult bundle
xcparse screenshots \
  --language --model \
  --activity-type userCreated \
  --test-status Success \
  /path/to/UITests.xcresult \
  ./screenshots

# 2. Upload to App Store Connect
./scripts/xcparse-to-appstore.sh \
  --app-id 1234567890 \
  --issuer-id "YOUR_ISSUER_ID" \
  --key-id "YOUR_KEY_ID" \
  --private-key "AuthKey_YOURKEYID.p8" \
  --screenshots-dir ./screenshots
```

### CI/CD Integration Example (GitHub Actions)

```yaml
name: Upload Screenshots to App Store Connect

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['**/UITests/**']

jobs:
  upload-screenshots:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install xcparse
        run: brew install chargepoint/xcparse/xcparse

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project YourApp.xcodeproj \
            -scheme "UITests" \
            -destination "platform=iOS Simulator,name=iPhone 16 Pro Max" \
            -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
            -destination "platform=iOS Simulator,name=iPad Pro 13-inch (M4)" \
            -resultBundlePath UITests.xcresult

      - name: Extract Screenshots
        run: |
          xcparse screenshots \
            --language --model \
            --activity-type userCreated \
            --test-status Success \
            UITests.xcresult \
            ./screenshots

      - name: Upload to App Store Connect
        env:
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_PRIVATE_KEY: ${{ secrets.ASC_PRIVATE_KEY }}
          APP_ID: ${{ secrets.APP_ID }}
        run: |
          echo "$ASC_PRIVATE_KEY" > /tmp/asc_key.p8
          ./scripts/xcparse-to-appstore.sh \
            --app-id "$APP_ID" \
            --issuer-id "$ASC_ISSUER_ID" \
            --key-id "$ASC_KEY_ID" \
            --private-key /tmp/asc_key.p8 \
            --screenshots-dir ./screenshots
          rm -f /tmp/asc_key.p8
```

---

## Device-to-Display-Type Mapping

When uploading screenshots, you must map the device model (from xcparse folder names) to an App Store Connect **screenshot display type**. The helper script handles this automatically.

| xcparse Model Name | Display Type Identifier | Screen Size |
|---|---|---|
| iPhone 16 Pro Max | `APP_IPHONE_67` | 6.7" |
| iPhone 15 Pro Max | `APP_IPHONE_67` | 6.7" |
| iPhone 14 Pro Max | `APP_IPHONE_67` | 6.7" |
| iPhone 16 Pro | `APP_IPHONE_65` | 6.5" |
| iPhone 15 Pro | `APP_IPHONE_65` | 6.5" |
| iPhone 14 Pro | `APP_IPHONE_65` | 6.5" |
| iPhone 16 | `APP_IPHONE_61` | 6.1" |
| iPhone SE (3rd generation) | `APP_IPHONE_55` | 5.5" |
| iPhone 8 Plus | `APP_IPHONE_55` | 5.5" |
| iPad Pro (12.9-inch) (6th generation) | `APP_IPAD_PRO_129` | 12.9" |
| iPad Pro (12.9-inch) (3rd generation) | `APP_IPAD_PRO_3GEN_129` | 12.9" |
| iPad Pro 13-inch (M4) | `APP_IPAD_PRO_129` | 12.9" |
| iPad Pro (11-inch) (4th generation) | `APP_IPAD_PRO_3GEN_11` | 11" |
| iPad (10th generation) | `APP_IPAD_105` | 10.5" |

> **Note:** Apple periodically updates the set of required and supported screenshot sizes. Check the [App Store Connect API documentation](https://developer.apple.com/documentation/appstoreconnectapi/screenshotdisplaytype) for the latest list.

---

## Language-to-Locale Mapping

xcparse exports language folder names that match the test configuration language. These must be mapped to App Store Connect locale codes:

| xcparse Language | App Store Connect Locale |
|---|---|
| en | en-US |
| en-GB | en-GB |
| fr | fr-FR |
| de | de-DE |
| ja | ja |
| zh-Hans | zh-Hans |
| zh-Hant | zh-Hant |
| ko | ko |
| es | es-ES |
| es-MX | es-MX |
| pt-BR | pt-BR |
| pt-PT | pt-PT |
| it | it |
| nl | nl-NL |
| ru | ru |
| ar | ar-SA |
| th | th |
| sv | sv |
| da | da |
| fi | fi |
| nb | no |
| tr | tr |
| el | el |
| id | id |
| ms | ms |
| vi | vi |
| hi | hi |
| hu | hu |
| pl | pl |
| cs | cs |
| sk | sk |
| uk | uk |
| hr | hr |
| ca | ca |
| ro | ro |
| he | he |

> The helper script includes a built-in mapping table. For languages not listed, the script will warn and skip the upload.

---

## Troubleshooting

### Common Issues

**"Authentication credentials are missing or invalid"**
- Verify your JWT token hasn't expired (max 20-minute lifetime)
- Regenerate the token and retry

**"A screenshot set for the specified display type already exists"**
- The script handles this by fetching existing sets. If you see this error when running manually, list existing sets first and reuse them.

**"The provided entity includes an attribute with a value that has already been used"**
- A screenshot with the same file name already exists in this set. Delete the existing screenshot first or use a unique file name.

**"The file size does not match"**
- Ensure the `fileSize` in the reservation matches the actual file byte count
- Use `stat -f%z filename` on macOS or `stat -c%s filename` on Linux

**"The screenshot dimensions are not valid"**
- App Store Connect requires specific pixel dimensions per display type
- Ensure your simulator matches the expected device for the display type
- Check [Apple's screenshot specifications](https://help.apple.com/app-store-connect/#/devd274dd925)

**"PREPARE_FOR_SUBMISSION version not found"**
- You need an app version in the "Prepare for Submission" state
- Create a new version in App Store Connect if needed

### Debug Tips

- Add `--verbose` to xcparse commands for detailed logging
- Use `python3 -m json.tool` to pretty-print API responses
- The helper script supports a `--dry-run` flag to preview what would be uploaded without making API calls
- Check screenshot dimensions: `sips -g pixelHeight -g pixelWidth screenshot.png`

---

## References

- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [App Screenshots API](https://developer.apple.com/documentation/appstoreconnectapi/app_store/app_metadata/app_screenshots)
- [Screenshot Display Types](https://developer.apple.com/documentation/appstoreconnectapi/screenshotdisplaytype)
- [Creating API Keys](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)
- [Generating Tokens for API Requests](https://developer.apple.com/documentation/appstoreconnectapi/generating_tokens_for_api_requests)
- [App Store Screenshot Specifications](https://help.apple.com/app-store-connect/#/devd274dd925)
- [xcparse README](../README.md)
- [Original Feature Request (ChargePoint/xcparse#49)](https://github.com/ChargePoint/xcparse/issues/49)
