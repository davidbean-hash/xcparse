#!/usr/bin/env bash
#
# xcparse-to-appstore.sh
#
# Upload screenshots extracted by xcparse to App Store Connect.
#
# Usage:
#   ./scripts/xcparse-to-appstore.sh \
#     --app-id 1234567890 \
#     --issuer-id "YOUR_ISSUER_ID" \
#     --key-id "YOUR_KEY_ID" \
#     --private-key "AuthKey_YOURKEYID.p8" \
#     --screenshots-dir ./screenshots
#
# The screenshots directory should be organized by xcparse with --language and --model:
#   screenshots/<language>/<device_model>/screenshot.png
#
# Optional flags:
#   --dry-run              Preview uploads without making API calls
#   --delete-existing      Delete existing screenshots before uploading
#   --version-string VER   Target a specific app version (default: latest PREPARE_FOR_SUBMISSION)

set -euo pipefail

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

API_BASE="https://api.appstoreconnect.apple.com/v1"

# --------------------------------------------------------------------------
# Configuration (set via CLI args)
# --------------------------------------------------------------------------

APP_ID=""
ISSUER_ID=""
KEY_ID=""
PRIVATE_KEY_PATH=""
SCREENSHOTS_DIR=""
DRY_RUN=false
DELETE_EXISTING=false
VERSION_STRING=""

# --------------------------------------------------------------------------
# Device model → App Store Connect screenshotDisplayType mapping
# --------------------------------------------------------------------------

declare -A DEVICE_TO_DISPLAY_TYPE=(
  # 6.9" iPhones
  ["iPhone 16 Pro Max"]="APP_IPHONE_67"
  # 6.7" iPhones
  ["iPhone 15 Pro Max"]="APP_IPHONE_67"
  ["iPhone 15 Plus"]="APP_IPHONE_67"
  ["iPhone 14 Pro Max"]="APP_IPHONE_67"
  ["iPhone 14 Plus"]="APP_IPHONE_67"
  ["iPhone 13 Pro Max"]="APP_IPHONE_67"
  ["iPhone 12 Pro Max"]="APP_IPHONE_67"
  # 6.5" / 6.1" Super Retina iPhones
  ["iPhone 16 Pro"]="APP_IPHONE_65"
  ["iPhone 15 Pro"]="APP_IPHONE_65"
  ["iPhone 14 Pro"]="APP_IPHONE_65"
  ["iPhone 13 Pro"]="APP_IPHONE_65"
  ["iPhone 11 Pro Max"]="APP_IPHONE_65"
  ["iPhone XS Max"]="APP_IPHONE_65"
  # Standard 6.1" iPhones
  ["iPhone 16"]="APP_IPHONE_61"
  ["iPhone 16e"]="APP_IPHONE_61"
  ["iPhone 15"]="APP_IPHONE_61"
  ["iPhone 14"]="APP_IPHONE_61"
  ["iPhone 13"]="APP_IPHONE_61"
  ["iPhone 12"]="APP_IPHONE_61"
  # 5.8" iPhones
  ["iPhone 11 Pro"]="APP_IPHONE_58"
  ["iPhone XS"]="APP_IPHONE_58"
  ["iPhone X"]="APP_IPHONE_58"
  # 5.5" iPhones
  ["iPhone 8 Plus"]="APP_IPHONE_55"
  ["iPhone 7 Plus"]="APP_IPHONE_55"
  ["iPhone SE (3rd generation)"]="APP_IPHONE_47"
  # 4.7" iPhones
  ["iPhone SE (2nd generation)"]="APP_IPHONE_47"
  ["iPhone 8"]="APP_IPHONE_47"
  # iPad Pro 12.9"
  ["iPad Pro (12.9-inch) (6th generation)"]="APP_IPAD_PRO_129"
  ["iPad Pro (12.9-inch) (5th generation)"]="APP_IPAD_PRO_129"
  ["iPad Pro (12.9-inch) (4th generation)"]="APP_IPAD_PRO_129"
  ["iPad Pro (12.9-inch) (3rd generation)"]="APP_IPAD_PRO_3GEN_129"
  ["iPad Pro 13-inch (M4)"]="APP_IPAD_PRO_129"
  # iPad Pro 11"
  ["iPad Pro (11-inch) (4th generation)"]="APP_IPAD_PRO_3GEN_11"
  ["iPad Pro (11-inch) (3rd generation)"]="APP_IPAD_PRO_3GEN_11"
  ["iPad Pro (11-inch) (2nd generation)"]="APP_IPAD_PRO_3GEN_11"
  ["iPad Pro (11-inch) (1st generation)"]="APP_IPAD_PRO_3GEN_11"
  ["iPad Pro 11-inch (M4)"]="APP_IPAD_PRO_3GEN_11"
  # iPad 10.5"
  ["iPad Air (5th generation)"]="APP_IPAD_105"
  ["iPad Air (4th generation)"]="APP_IPAD_105"
  ["iPad (10th generation)"]="APP_IPAD_105"
  ["iPad (9th generation)"]="APP_IPAD_105"
  # iPad 9.7"
  ["iPad (8th generation)"]="APP_IPAD_97"
)

# --------------------------------------------------------------------------
# Language → App Store Connect locale mapping
# --------------------------------------------------------------------------

declare -A LANGUAGE_TO_LOCALE=(
  ["en"]="en-US"
  ["en-US"]="en-US"
  ["en-GB"]="en-GB"
  ["en-AU"]="en-AU"
  ["en-CA"]="en-CA"
  ["fr"]="fr-FR"
  ["fr-FR"]="fr-FR"
  ["fr-CA"]="fr-CA"
  ["de"]="de-DE"
  ["de-DE"]="de-DE"
  ["ja"]="ja"
  ["zh-Hans"]="zh-Hans"
  ["zh-Hant"]="zh-Hant"
  ["zh-Hant-TW"]="zh-Hant"
  ["ko"]="ko"
  ["es"]="es-ES"
  ["es-ES"]="es-ES"
  ["es-MX"]="es-MX"
  ["pt-BR"]="pt-BR"
  ["pt-PT"]="pt-PT"
  ["pt"]="pt-PT"
  ["it"]="it"
  ["nl"]="nl-NL"
  ["nl-NL"]="nl-NL"
  ["ru"]="ru"
  ["ar"]="ar-SA"
  ["th"]="th"
  ["sv"]="sv"
  ["da"]="da"
  ["fi"]="fi"
  ["nb"]="no"
  ["no"]="no"
  ["tr"]="tr"
  ["el"]="el"
  ["id"]="id"
  ["ms"]="ms"
  ["vi"]="vi"
  ["hi"]="hi"
  ["hu"]="hu"
  ["pl"]="pl"
  ["cs"]="cs"
  ["sk"]="sk"
  ["uk"]="uk"
  ["hr"]="hr"
  ["ca"]="ca"
  ["ro"]="ro"
  ["he"]="he"
)

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

log() { echo "[xcparse-to-appstore] $*"; }
warn() { echo "[xcparse-to-appstore] WARNING: $*" >&2; }
error() { echo "[xcparse-to-appstore] ERROR: $*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: xcparse-to-appstore.sh [OPTIONS]

Required:
  --app-id ID               Your App Store app ID
  --issuer-id ID            App Store Connect API issuer ID
  --key-id ID               App Store Connect API key ID
  --private-key PATH        Path to .p8 private key file
  --screenshots-dir DIR     Directory of screenshots (xcparse output with --language --model)

Optional:
  --dry-run                 Preview what would be uploaded without making API calls
  --delete-existing         Delete existing screenshots in each set before uploading
  --version-string VER      Target a specific app version string
  -h, --help                Show this help message

The screenshots directory should be organized as:
  <screenshots-dir>/<language>/<device_model>/<screenshot>.png

Example:
  xcparse screenshots --language --model --activity-type userCreated \
    /path/to/Test.xcresult ./screenshots

  ./scripts/xcparse-to-appstore.sh \
    --app-id 1234567890 \
    --issuer-id "57246542-96fe-1a63-e053-0824d011072a" \
    --key-id "2X9R4HXF34" \
    --private-key AuthKey_2X9R4HXF34.p8 \
    --screenshots-dir ./screenshots
EOF
  exit 0
}

# --------------------------------------------------------------------------
# JWT Generation
# --------------------------------------------------------------------------

generate_jwt() {
  local header payload signature

  header=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$KEY_ID" \
    | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

  local now
  now=$(date +%s)
  local exp=$((now + 1200))

  payload=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' \
    "$ISSUER_ID" "$now" "$exp" \
    | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

  # openssl dgst produces a DER-encoded ECDSA signature, but JWT ES256
  # requires the raw (r || s) concatenation (64 bytes for P-256).
  local der_sig
  der_sig=$(printf '%s.%s' "$header" "$payload" \
    | openssl dgst -sha256 -sign "$PRIVATE_KEY_PATH")

  signature=$(printf '%s' "$der_sig" | python3 -c "
import sys
der = sys.stdin.buffer.read()
assert der[0] == 0x30
idx = 2
assert der[idx] == 0x02
r_len = der[idx+1]
r = der[idx+2:idx+2+r_len]
idx += 2 + r_len
assert der[idx] == 0x02
s_len = der[idx+1]
s = der[idx+2:idx+2+s_len]
r = r[-32:].rjust(32, b'\\x00')
s = s[-32:].rjust(32, b'\\x00')
sys.stdout.buffer.write(r + s)
" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')

  echo "${header}.${payload}.${signature}"
}

# --------------------------------------------------------------------------
# API Helpers
# --------------------------------------------------------------------------

api_get() {
  local url="$1"
  curl -sf -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" "$url"
}

api_post() {
  local url="$1"
  local body="$2"
  curl -sf -X POST \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$url"
}

api_patch() {
  local url="$1"
  local body="$2"
  curl -sf -X PATCH \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$url"
}

api_delete() {
  local url="$1"
  curl -sf -X DELETE -H "Authorization: Bearer $JWT" "$url"
}

# --------------------------------------------------------------------------
# Lookup: App Store version in PREPARE_FOR_SUBMISSION state
# --------------------------------------------------------------------------

get_version_id() {
  local filter="filter[platform]=IOS"
  if [[ -n "$VERSION_STRING" ]]; then
    filter="${filter}&filter[versionString]=${VERSION_STRING}"
  fi
  filter="${filter}&filter[appStoreState]=PREPARE_FOR_SUBMISSION"

  local response
  response=$(api_get "${API_BASE}/apps/${APP_ID}/appStoreVersions?${filter}") \
    || error "Failed to fetch App Store versions. Check your credentials and app ID."

  local version_id
  version_id=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
versions = data.get('data', [])
if versions:
    print(versions[0]['id'])
else:
    sys.exit(1)
" 2>/dev/null) || error "No App Store version found in PREPARE_FOR_SUBMISSION state."

  echo "$version_id"
}

# --------------------------------------------------------------------------
# Lookup/Create: version localization for a given locale
# --------------------------------------------------------------------------

get_or_create_localization() {
  local version_id="$1"
  local locale="$2"

  local response
  response=$(api_get "${API_BASE}/appStoreVersions/${version_id}/appStoreVersionLocalizations") \
    || error "Failed to fetch localizations for version ${version_id}"

  local loc_id
  loc_id=$(echo "$response" | python3 -c "
import sys, json
locale = '${locale}'
data = json.load(sys.stdin)
for loc in data.get('data', []):
    if loc['attributes']['locale'] == locale:
        print(loc['id'])
        sys.exit(0)
sys.exit(1)
" 2>/dev/null)

  if [[ -n "$loc_id" ]]; then
    echo "$loc_id"
    return
  fi

  log "Creating localization for locale: $locale"
  if $DRY_RUN; then
    echo "dry-run-localization-${locale}"
    return
  fi

  response=$(api_post "${API_BASE}/appStoreVersionLocalizations" "$(cat <<EOF
{
  "data": {
    "type": "appStoreVersionLocalizations",
    "attributes": { "locale": "${locale}" },
    "relationships": {
      "appStoreVersion": {
        "data": { "type": "appStoreVersions", "id": "${version_id}" }
      }
    }
  }
}
EOF
)") || error "Failed to create localization for locale ${locale}"

  echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])"
}

# --------------------------------------------------------------------------
# Lookup/Create: screenshot set for a given localization + display type
# --------------------------------------------------------------------------

get_or_create_screenshot_set() {
  local localization_id="$1"
  local display_type="$2"

  local response
  response=$(api_get "${API_BASE}/appStoreVersionLocalizations/${localization_id}/appScreenshotSets") \
    || error "Failed to fetch screenshot sets"

  local set_id
  set_id=$(echo "$response" | python3 -c "
import sys, json
dt = '${display_type}'
data = json.load(sys.stdin)
for s in data.get('data', []):
    if s['attributes']['screenshotDisplayType'] == dt:
        print(s['id'])
        sys.exit(0)
sys.exit(1)
" 2>/dev/null)

  if [[ -n "$set_id" ]]; then
    echo "$set_id"
    return
  fi

  log "Creating screenshot set: $display_type"
  if $DRY_RUN; then
    echo "dry-run-set-${display_type}"
    return
  fi

  response=$(api_post "${API_BASE}/appScreenshotSets" "$(cat <<EOF
{
  "data": {
    "type": "appScreenshotSets",
    "attributes": { "screenshotDisplayType": "${display_type}" },
    "relationships": {
      "appStoreVersionLocalization": {
        "data": { "type": "appStoreVersionLocalizations", "id": "${localization_id}" }
      }
    }
  }
}
EOF
)") || error "Failed to create screenshot set for ${display_type}"

  echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])"
}

# --------------------------------------------------------------------------
# Delete existing screenshots in a set
# --------------------------------------------------------------------------

delete_screenshots_in_set() {
  local set_id="$1"
  local response
  response=$(api_get "${API_BASE}/appScreenshotSets/${set_id}/appScreenshots") || return 0

  local ids
  ids=$(echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('data', []):
    print(s['id'])
" 2>/dev/null)

  for sid in $ids; do
    log "  Deleting existing screenshot: $sid"
    if ! $DRY_RUN; then
      api_delete "${API_BASE}/appScreenshots/${sid}" || warn "Failed to delete screenshot ${sid}"
    fi
  done
}

# --------------------------------------------------------------------------
# Upload a single screenshot
# --------------------------------------------------------------------------

upload_screenshot() {
  local set_id="$1"
  local file_path="$2"
  local file_name
  file_name=$(basename "$file_path")
  local file_size
  file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path")

  log "  Uploading: $file_name ($file_size bytes)"

  if $DRY_RUN; then
    log "  [DRY RUN] Would upload $file_name to set $set_id"
    return 0
  fi

  # Step 1: Reserve
  local reserve_response
  reserve_response=$(api_post "${API_BASE}/appScreenshots" "$(cat <<EOF
{
  "data": {
    "type": "appScreenshots",
    "attributes": {
      "fileName": "${file_name}",
      "fileSize": ${file_size}
    },
    "relationships": {
      "appScreenshotSet": {
        "data": { "type": "appScreenshotSets", "id": "${set_id}" }
      }
    }
  }
}
EOF
)") || { warn "Failed to reserve upload for $file_name"; return 1; }

  local screenshot_id
  screenshot_id=$(echo "$reserve_response" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['id'])")

  # Step 2: Upload binary parts
  export UPLOAD_FILE_PATH="$file_path"
  echo "$reserve_response" | python3 -c "
import os, sys, json, subprocess

file_path = os.environ['UPLOAD_FILE_PATH']
data = json.load(sys.stdin)
operations = data['data']['attributes']['uploadOperations']

for op in operations:
    url = op['url']
    offset = op['offset']
    length = op['length']
    headers = op.get('requestHeaders', [])

    cmd = ['curl', '-sf', '-X', 'PUT']
    for h in headers:
        cmd.extend(['-H', f\"{h['name']}: {h['value']}\"])

    # Read the specific chunk
    with open(file_path, 'rb') as f:
        f.seek(offset)
        chunk = f.read(length)

    result = subprocess.run(
        cmd + [url, '--data-binary', '@-'],
        input=chunk,
        capture_output=True
    )
    if result.returncode != 0:
        print(f'Upload failed for chunk at offset {offset}', file=sys.stderr)
        sys.exit(1)
" || { warn "Failed to upload binary for $file_name"; return 1; }

  # Step 3: Compute checksum and commit
  local checksum
  if command -v md5 &>/dev/null; then
    checksum=$(md5 -q "$file_path")
  else
    checksum=$(md5sum "$file_path" | awk '{print $1}')
  fi

  api_patch "${API_BASE}/appScreenshots/${screenshot_id}" "$(cat <<EOF
{
  "data": {
    "type": "appScreenshots",
    "id": "${screenshot_id}",
    "attributes": {
      "sourceFileChecksum": "${checksum}",
      "uploaded": true
    }
  }
}
EOF
)" || { warn "Failed to commit upload for $file_name"; return 1; }

  log "  Uploaded: $file_name"
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-id)         APP_ID="$2"; shift 2 ;;
      --issuer-id)      ISSUER_ID="$2"; shift 2 ;;
      --key-id)         KEY_ID="$2"; shift 2 ;;
      --private-key)    PRIVATE_KEY_PATH="$2"; shift 2 ;;
      --screenshots-dir) SCREENSHOTS_DIR="$2"; shift 2 ;;
      --dry-run)        DRY_RUN=true; shift ;;
      --delete-existing) DELETE_EXISTING=true; shift ;;
      --version-string) VERSION_STRING="$2"; shift 2 ;;
      -h|--help)        usage ;;
      *)                error "Unknown option: $1" ;;
    esac
  done

  [[ -n "$APP_ID" ]]          || error "Missing --app-id"
  [[ -n "$ISSUER_ID" ]]       || error "Missing --issuer-id"
  [[ -n "$KEY_ID" ]]          || error "Missing --key-id"
  [[ -n "$PRIVATE_KEY_PATH" ]] || error "Missing --private-key"
  [[ -n "$SCREENSHOTS_DIR" ]] || error "Missing --screenshots-dir"
  [[ -f "$PRIVATE_KEY_PATH" ]] || error "Private key not found: $PRIVATE_KEY_PATH"
  [[ -d "$SCREENSHOTS_DIR" ]] || error "Screenshots directory not found: $SCREENSHOTS_DIR"
}

main() {
  parse_args "$@"

  log "Generating JWT..."
  JWT=$(generate_jwt)

  if $DRY_RUN; then
    log "=== DRY RUN MODE ==="
  fi

  log "Looking up App Store version for app $APP_ID..."
  local version_id
  version_id=$(get_version_id)
  log "Found version: $version_id"

  local upload_count=0
  local skip_count=0
  local error_count=0

  # Walk the directory: <language>/<device_model>/<screenshot>
  for lang_dir in "$SCREENSHOTS_DIR"/*/; do
    [[ -d "$lang_dir" ]] || continue
    local language
    language=$(basename "$lang_dir")

    # Map language to locale
    local locale="${LANGUAGE_TO_LOCALE[$language]:-}"
    if [[ -z "$locale" ]]; then
      # Try using the language as-is (it might already be a valid locale)
      locale="$language"
      warn "No locale mapping for '$language', using as-is: $locale"
    fi

    log "Processing language: $language -> locale: $locale"

    local localization_id
    localization_id=$(get_or_create_localization "$version_id" "$locale")

    for device_dir in "$lang_dir"/*/; do
      [[ -d "$device_dir" ]] || continue
      local device_model
      device_model=$(basename "$device_dir")

      # Map device to display type
      local display_type="${DEVICE_TO_DISPLAY_TYPE[$device_model]:-}"
      if [[ -z "$display_type" ]]; then
        warn "No display type mapping for device '$device_model' — skipping"
        skip_count=$((skip_count + 1))
        continue
      fi

      log "  Device: $device_model -> Display type: $display_type"

      local set_id
      set_id=$(get_or_create_screenshot_set "$localization_id" "$display_type")

      if $DELETE_EXISTING; then
        delete_screenshots_in_set "$set_id"
      fi

      # Upload each screenshot
      for screenshot in "$device_dir"/*.png "$device_dir"/*.jpg "$device_dir"/*.jpeg; do
        [[ -f "$screenshot" ]] || continue

        if upload_screenshot "$set_id" "$screenshot"; then
          upload_count=$((upload_count + 1))
        else
          error_count=$((error_count + 1))
        fi
      done
    done
  done

  log "========================================"
  log "Upload complete!"
  log "  Uploaded: $upload_count screenshots"
  log "  Skipped:  $skip_count (unmapped devices)"
  log "  Errors:   $error_count"
  log "========================================"

  if [[ $error_count -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
