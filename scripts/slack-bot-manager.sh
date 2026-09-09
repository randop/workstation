#!/usr/bin/env bash
# =============================================================================
# slack-bot-manager.sh
# Slack AppBot Manager
# =============================================================================
# Features:
#   - Bot operations (post, update, delete messages, channels, users, files...)
#   - App Manifest APIs (create / update / delete / export / validate apps)
#   - Config token rotation
#   - Proper retries, rate-limit handling, structured logging
# =============================================================================
# Requirements: bash >= 4, curl, jq
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SLACK_API_BASE="https://slack.com/api"
readonly DEFAULT_TIMEOUT=30
readonly LOG_FILE="${SLACK_LOG_FILE:-slack.log}"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=2

# Colors
if [[ -t 1 ]]; then
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' CYAN='\033[0;36m' NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
log() {
  local level="$1"
  shift
  local msg="$*"
  local ts
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo -e "${ts} [${level}] ${msg}" | tee -a "${LOG_FILE}" >&2
}

info() { log "INFO" "$*"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }
die() {
  error "$*"
  exit 1
}

# ---------------------------------------------------------------------------
# Token helpers
# ---------------------------------------------------------------------------
require_bot_token() {
  if [[ -z "${SLACK_BOT_TOKEN:-}" ]]; then
    die "SLACK_BOT_TOKEN is required for this command (xoxb-...)"
  fi
}

require_config_token() {
  if [[ -z "${SLACK_CONFIG_TOKEN:-}" ]]; then
    die "SLACK_CONFIG_TOKEN is required for App Manifest commands (xoxe.xoxp-...)"
  fi
}

# ---------------------------------------------------------------------------
# Core API caller
# ---------------------------------------------------------------------------
# Usage: slack_api <method> <http_method> <token_var> [json_data] [query_string]
slack_api() {
  local method="$1"
  local http_method="${2:-POST}"
  local token_var="$3" # "bot" or "config"
  local data="${4:-}"
  local query="${5:-}"

  local token
  if [[ "${token_var}" == "bot" ]]; then
    require_bot_token
    token="${SLACK_BOT_TOKEN}"
  else
    require_config_token
    token="${SLACK_CONFIG_TOKEN}"
  fi

  local url="${SLACK_API_BASE}/${method}"
  [[ -n "${query}" ]] && url="${url}?${query}"

  local attempt=1
  local response http_code

  while ((attempt <= MAX_RETRIES)); do
    local curl_args=(
      -s -S
      --max-time "${DEFAULT_TIMEOUT}"
      -w "\n%{http_code}"
      -H "Authorization: Bearer ${token}"
      -H "Content-type: application/json; charset=utf-8"
      -X "${http_method}"
    )

    [[ -n "${data}" ]] && curl_args+=(--data "${data}")

    response="$(curl "${curl_args[@]}" "${url}" 2>/dev/null || true)"
    http_code="$(echo "${response}" | tail -n1)"
    response="$(echo "${response}" | sed '$d')"

    if [[ -z "${http_code}" || "${http_code}" == "000" ]]; then
      warn "Attempt ${attempt}/${MAX_RETRIES}: network error on ${method}"
      sleep $((RETRY_DELAY * attempt))
      ((attempt++))
      continue
    fi

    if [[ "${http_code}" == "429" ]]; then
      local retry_after
      retry_after="$(echo "${response}" | jq -r '.retry_after // 5' 2>/dev/null || echo 5)"
      warn "Rate limited. Waiting ${retry_after}s..."
      sleep "${retry_after}"
      ((attempt++))
      continue
    fi

    if ! echo "${response}" | jq -e . >/dev/null 2>&1; then
      error "Invalid JSON from ${method}"
      echo "${response}" >&2
      return 1
    fi

    local ok
    ok="$(echo "${response}" | jq -r '.ok')"

    if [[ "${ok}" == "true" ]]; then
      echo "${response}"
      return 0
    fi

    local err
    err="$(echo "${response}" | jq -r '.error // "unknown_error"')"
    error "Slack API error on ${method}: ${err}"
    echo "${response}" | jq . >&2
    return 1
  done

  die "Failed after ${MAX_RETRIES} attempts: ${method}"
}

pp() { jq -C . 2>/dev/null || jq .; }

# =============================================================================
# BOT OPERATIONS (require SLACK_BOT_TOKEN)
# =============================================================================

cmd_auth_test() {
  info "Testing bot authentication..."
  slack_api "auth.test" "POST" "bot" | pp
}

cmd_post_message() {
  local channel="${1:-}" text="${2:-}"
  [[ -z "${channel}" || -z "${text}" ]] && die "Usage: $SCRIPT_NAME post-message <channel> <text>"

  local payload
  payload="$(jq -n --arg c "${channel}" --arg t "${text}" '{channel:$c, text:$t}')"
  info "Posting message to ${channel}..."
  slack_api "chat.postMessage" "POST" "bot" "${payload}" | pp
}

cmd_post_blocks() {
  local channel="${1:-}" blocks_file="${2:-}"
  [[ -z "${channel}" || -z "${blocks_file}" ]] && die "Usage: $SCRIPT_NAME post-blocks <channel> <blocks.json>"
  [[ ! -f "${blocks_file}" ]] && die "File not found: ${blocks_file}"

  local payload
  payload="$(jq -n --arg c "${channel}" --slurpfile b "${blocks_file}" \
    '{channel:$c, blocks:$b[0], text:"Fallback text"}')"
  info "Posting Block Kit message..."
  slack_api "chat.postMessage" "POST" "bot" "${payload}" | pp
}

cmd_update_message() {
  local channel="${1:-}" ts="${2:-}" text="${3:-}"
  [[ -z "${channel}" || -z "${ts}" || -z "${text}" ]] &&
    die "Usage: $SCRIPT_NAME update-message <channel> <ts> <text>"

  local payload
  payload="$(jq -n --arg c "${channel}" --arg ts "${ts}" --arg t "${text}" \
    '{channel:$c, ts:$ts, text:$t}')"
  slack_api "chat.update" "POST" "bot" "${payload}" | pp
}

cmd_delete_message() {
  local channel="${1:-}" ts="${2:-}"
  [[ -z "${channel}" || -z "${ts}" ]] && die "Usage: $SCRIPT_NAME delete-message <channel> <ts>"

  local payload
  payload="$(jq -n --arg c "${channel}" --arg ts "${ts}" '{channel:$c, ts:$ts}')"
  slack_api "chat.delete" "POST" "bot" "${payload}" | pp
}

cmd_list_channels() {
  local types="${1:-public_channel,private_channel}" limit="${2:-200}"
  slack_api "conversations.list" "GET" "bot" "" "types=${types}&limit=${limit}&exclude_archived=true" | pp
}

cmd_channel_info() {
  local channel="${1:-}"
  [[ -z "${channel}" ]] && die "Usage: $SCRIPT_NAME channel-info <channel_id>"
  slack_api "conversations.info" "GET" "bot" "" "channel=${channel}" | pp
}

cmd_list_users() {
  local limit="${1:-200}"
  slack_api "users.list" "GET" "bot" "" "limit=${limit}" | pp
}

cmd_user_info() {
  local user="${1:-}"
  [[ -z "${user}" ]] && die "Usage: $SCRIPT_NAME user-info <user_id>"
  slack_api "users.info" "GET" "bot" "" "user=${user}" | pp
}

cmd_join_channel() {
  local channel="${1:-}"
  [[ -z "${channel}" ]] && die "Usage: $SCRIPT_NAME join-channel <channel_id>"
  local payload
  payload="$(jq -n --arg c "${channel}" '{channel:$c}')"
  slack_api "conversations.join" "POST" "bot" "${payload}" | pp
}

cmd_leave_channel() {
  local channel="${1:-}"
  [[ -z "${channel}" ]] && die "Usage: $SCRIPT_NAME leave-channel <channel_id>"
  local payload
  payload="$(jq -n --arg c "${channel}" '{channel:$c}')"
  slack_api "conversations.leave" "POST" "bot" "${payload}" | pp
}

cmd_upload_file() {
  local channels="${1:-}" file_path="${2:-}" title="${3:-}"
  [[ -z "${channels}" || -z "${file_path}" ]] &&
    die "Usage: $SCRIPT_NAME upload-file <channels> <file_path> [title]"
  [[ ! -f "${file_path}" ]] && die "File not found: ${file_path}"

  info "Uploading ${file_path}..."
  curl -s -S --max-time 60 \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -F "channels=${channels}" \
    -F "file=@${file_path}" \
    ${title:+-F "title=${title}"} \
    "${SLACK_API_BASE}/files.upload" | pp
}

cmd_revoke_bot_token() {
  warn "This will revoke the current BOT token. Type 'yes' to confirm:"
  read -r confirm
  [[ "${confirm}" != "yes" ]] && {
    info "Aborted."
    return 0
  }
  slack_api "auth.revoke" "POST" "bot" | pp
}

# =============================================================================
# APP MANIFEST MANAGEMENT (require SLACK_CONFIG_TOKEN)
# =============================================================================

cmd_app_create() {
  local manifest_file="${1:-}"
  [[ -z "${manifest_file}" ]] && die "Usage: $SCRIPT_NAME app-create <manifest.json|yaml>"
  [[ ! -f "${manifest_file}" ]] && die "Manifest file not found: ${manifest_file}"

  # Accept both JSON and YAML (convert YAML → JSON if needed)
  local manifest_json
  if [[ "${manifest_file}" == *.yaml || "${manifest_file}" == *.yml ]]; then
    command -v yq >/dev/null || die "yq is required to convert YAML manifests"
    manifest_json="$(yq -o=json "${manifest_file}")"
  else
    manifest_json="$(cat "${manifest_file}")"
  fi

  # Validate JSON
  echo "${manifest_json}" | jq -e . >/dev/null || die "Invalid JSON in manifest"

  local payload
  payload="$(jq -n --arg m "${manifest_json}" '{manifest: $m}')"

  info "Creating Slack app from manifest..."
  local result
  result="$(slack_api "apps.manifest.create" "POST" "config" "${payload}")"
  echo "${result}" | pp

  local app_id
  app_id="$(echo "${result}" | jq -r '.app_id // empty')"
  if [[ -n "${app_id}" ]]; then
    info "App created successfully → App ID: ${CYAN}${app_id}${NC}"
    info "Next step: install the app using the oauth_authorize_url from the response"
  fi
}

cmd_app_update() {
  local app_id="${1:-}" manifest_file="${2:-}"
  [[ -z "${app_id}" || -z "${manifest_file}" ]] &&
    die "Usage: $SCRIPT_NAME app-update <app_id> <manifest.json>"

  [[ ! -f "${manifest_file}" ]] && die "Manifest file not found"

  local manifest_json
  manifest_json="$(cat "${manifest_file}")"
  echo "${manifest_json}" | jq -e . >/dev/null || die "Invalid JSON"

  local payload
  payload="$(jq -n --arg id "${app_id}" --arg m "${manifest_json}" \
    '{app_id: $id, manifest: $m}')"

  info "Updating app ${app_id}..."
  slack_api "apps.manifest.update" "POST" "config" "${payload}" | pp
}

cmd_app_delete() {
  local app_id="${1:-}"
  [[ -z "${app_id}" ]] && die "Usage: $SCRIPT_NAME app-delete <app_id>"

  warn "This will PERMANENTLY delete app ${app_id}. Type 'yes' to confirm:"
  read -r confirm
  [[ "${confirm}" != "yes" ]] && {
    info "Aborted."
    return 0
  }

  local payload
  payload="$(jq -n --arg id "${app_id}" '{app_id: $id}')"
  slack_api "apps.manifest.delete" "POST" "config" "${payload}" | pp
}

cmd_app_export() {
  local app_id="${1:-}"
  [[ -z "${app_id}" ]] && die "Usage: $SCRIPT_NAME app-export <app_id>"

  local payload
  payload="$(jq -n --arg id "${app_id}" '{app_id: $id}')"
  info "Exporting manifest for ${app_id}..."
  slack_api "apps.manifest.export" "POST" "config" "${payload}" | pp
}

cmd_app_validate() {
  local manifest_file="${1:-}"
  [[ -z "${manifest_file}" ]] && die "Usage: $SCRIPT_NAME app-validate <manifest.json>"
  [[ ! -f "${manifest_file}" ]] && die "File not found"

  local manifest_json
  manifest_json="$(cat "${manifest_file}")"

  local payload
  payload="$(jq -n --arg m "${manifest_json}" '{manifest: $m}')"

  info "Validating manifest..."
  slack_api "apps.manifest.validate" "POST" "config" "${payload}" | pp
}

cmd_rotate_config_token() {
  if [[ -z "${SLACK_CONFIG_REFRESH_TOKEN:-}" ]]; then
    die "SLACK_CONFIG_REFRESH_TOKEN is required to rotate the config token"
  fi

  info "Rotating App Configuration Token..."
  local payload
  payload="$(jq -n --arg rt "${SLACK_CONFIG_REFRESH_TOKEN}" '{refresh_token: $rt}')"

  local result
  result="$(curl -s -S -X POST \
    -H "Content-type: application/json" \
    --data "${payload}" \
    "${SLACK_API_BASE}/tooling.tokens.rotate")"

  echo "${result}" | pp

  local new_token new_refresh
  new_token="$(echo "${result}" | jq -r '.token // empty')"
  new_refresh="$(echo "${result}" | jq -r '.refresh_token // empty')"

  if [[ -n "${new_token}" ]]; then
    info "New config token received. Update your environment:"
    echo -e "${GREEN}export SLACK_CONFIG_TOKEN=\"${new_token}\"${NC}"
    echo -e "${GREEN}export SLACK_CONFIG_REFRESH_TOKEN=\"${new_refresh}\"${NC}"
  fi
}

# =============================================================================
# Usage
# =============================================================================
usage() {
  cat <<EOF
${BLUE}${SCRIPT_NAME}${NC} – Slack AppBot Manager

${CYAN}Environment variables:${NC}
  SLACK_BOT_TOKEN              Bot token (xoxb-...) – for operational commands
  SLACK_CONFIG_TOKEN           App config token (xoxe.xoxp-...) – for app management
  SLACK_CONFIG_REFRESH_TOKEN   Refresh token for config token rotation
  SLACK_LOG_FILE               Optional log path (default: /var/log/slack-bot-manager.log)

${CYAN}Bot Operations:${NC}
  auth-test
  post-message <channel> <text>
  post-blocks  <channel> <blocks.json>
  update-message <channel> <ts> <text>
  delete-message <channel> <ts>
  list-channels [types] [limit]
  channel-info <channel_id>
  list-users [limit]
  user-info <user_id>
  join-channel <channel_id>
  leave-channel <channel_id>
  upload-file <channels> <path> [title]
  revoke-bot-token

${CYAN}App Manifest Management:${NC}
  app-create   <manifest.json|yaml>     Create new app from manifest
  app-update   <app_id> <manifest.json> Update existing app
  app-delete   <app_id>                 Permanently delete app
  app-export   <app_id>                 Export app manifest
  app-validate <manifest.json>          Validate a manifest
  rotate-config-token                   Rotate expired config token

${CYAN}Examples:${NC}
  # Bot operations
  export SLACK_BOT_TOKEN="xoxb-..."
  $SCRIPT_NAME auth-test
  $SCRIPT_NAME post-message C0123456789 "Hello Randolph!"

  # App management
  export SLACK_CONFIG_TOKEN="xoxe.xoxp-..."
  $SCRIPT_NAME app-create ./manifest.json
  $SCRIPT_NAME app-export A012ABCD0A0

EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true

  local cmd="${1:-}"
  shift || true

  case "${cmd}" in
  # Bot
  auth-test) cmd_auth_test "$@" ;;
  post-message) cmd_post_message "$@" ;;
  post-blocks) cmd_post_blocks "$@" ;;
  update-message) cmd_update_message "$@" ;;
  delete-message) cmd_delete_message "$@" ;;
  list-channels) cmd_list_channels "$@" ;;
  channel-info) cmd_channel_info "$@" ;;
  list-users) cmd_list_users "$@" ;;
  user-info) cmd_user_info "$@" ;;
  join-channel) cmd_join_channel "$@" ;;
  leave-channel) cmd_leave_channel "$@" ;;
  upload-file) cmd_upload_file "$@" ;;
  revoke-bot-token) cmd_revoke_bot_token "$@" ;;

  # App Manifest
  app-create) cmd_app_create "$@" ;;
  app-update) cmd_app_update "$@" ;;
  app-delete) cmd_app_delete "$@" ;;
  app-export) cmd_app_export "$@" ;;
  app-validate) cmd_app_validate "$@" ;;
  rotate-config-token) cmd_rotate_config_token "$@" ;;

  -h | --help | help | "")
    usage
    exit 0
    ;;
  *) die "Unknown command: ${cmd}. Run with --help." ;;
  esac
}

main "$@"
