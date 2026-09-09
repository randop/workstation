#!/usr/bin/env bash
# slack-bot-manager.sh
# version: 1.0.1 (Sep 9, 2026)
# Slack AppBot Manager
#
# Requirements: bash >= 4, curl, jq
# Optional: yq (for YAML manifests)

set -euo pipefail
IFS=$'\n\t'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="1.0.1"
readonly SLACK_API_BASE="https://slack.com/api"
readonly DEFAULT_TIMEOUT=30
readonly LOG_FILE="${SLACK_LOG_FILE:-slack.log}"
readonly MAX_RETRIES=3
readonly RETRY_DELAY=2

if [[ -t 1 ]]; then
  readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' CYAN='\033[0;36m' NC='\033[0m'
else
  readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

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

require_bot_token() {
  if [[ -z "${SLACK_BOT_TOKEN:-}" ]]; then
    die "SLACK_BOT_TOKEN is required (starts with xoxb-)"
  fi
}

require_config_token() {
  if [[ -z "${SLACK_CONFIG_TOKEN:-}" ]]; then
    die "SLACK_CONFIG_TOKEN is required (starts with xoxe.xoxp-)"
  fi
}

# Core API caller
# Usage: slack_api <method> <http_method> <token_type> [json_body] [query]
slack_api() {
  local method="$1"
  local http_method="${2:-POST}"
  local token_type="$3"
  local data="${4:-}"
  local query="${5:-}"

  local token
  if [[ "${token_type}" == "bot" ]]; then
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
      warn "Attempt ${attempt}/${MAX_RETRIES}: network problem calling ${method}"
      sleep $((RETRY_DELAY * attempt))
      ((attempt++))
      continue
    fi

    if [[ "${http_code}" == "429" ]]; then
      local retry_after
      retry_after="$(echo "${response}" | jq -r '.retry_after // 5' 2>/dev/null || echo 5)"
      warn "Rate limited. Waiting ${retry_after} seconds..."
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
    error "Slack error on ${method}: ${err}"
    echo "${response}" | jq . >&2
    return 1
  done

  die "Gave up after ${MAX_RETRIES} attempts on ${method}"
}

pp() {
  jq -C . 2>/dev/null || jq .
}

# ---------------------------------------------------------------------------
# Bot commands
# ---------------------------------------------------------------------------

cmd_auth_test() {
  info "Checking authentication..."
  slack_api "auth.test" "POST" "bot" | pp
}

cmd_post_message() {
  local channel="${1:-}" text="${2:-}"
  [[ -z "${channel}" || -z "${text}" ]] && die "Usage: $SCRIPT_NAME post-message <channel> <text>"

  local payload
  payload="$(jq -n --arg c "${channel}" --arg t "${text}" '{channel:$c, text:$t}')"
  info "Sending message to ${channel}..."
  slack_api "chat.postMessage" "POST" "bot" "${payload}" | pp
}

cmd_post_blocks() {
  local channel="${1:-}" blocks_file="${2:-}"
  [[ -z "${channel}" || -z "${blocks_file}" ]] && die "Usage: $SCRIPT_NAME post-blocks <channel> <blocks.json>"
  [[ ! -f "${blocks_file}" ]] && die "File not found: ${blocks_file}"

  local payload
  payload="$(jq -n --arg c "${channel}" --slurpfile b "${blocks_file}" \
    '{channel:$c, blocks:$b[0], text:"Fallback text"}')"
  info "Sending Block Kit message..."
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

cmd_create_channel() {
  local name="${1:-}"
  local is_private="${2:-false}"

  [[ -z "${name}" ]] && die "Usage: $SCRIPT_NAME create-channel <name> [true|false]"

  case "${is_private}" in
  true | false) ;;
  *) die "Second argument must be true or false (private channel)" ;;
  esac

  local payload
  payload="$(jq -n --arg n "${name}" --argjson p "${is_private}" \
    '{name: $n, is_private: $p}')"

  info "Creating channel #${name}..."
  slack_api "conversations.create" "POST" "bot" "${payload}" | pp
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

cmd_set_presence() {
  local presence="${1:-}"
  [[ -z "${presence}" ]] && die "Usage: $SCRIPT_NAME set-presence <auto|away>"

  case "${presence}" in
  auto | away) ;;
  *) die "Presence must be 'auto' or 'away'" ;;
  esac

  local payload
  payload="$(jq -n --arg p "${presence}" '{presence: $p}')"

  info "Setting presence to ${presence}..."
  slack_api "users.setPresence" "POST" "bot" "${payload}" | pp
}

cmd_revoke_bot_token() {
  warn "This will revoke the current bot token. Type 'yes' to continue:"
  read -r confirm
  [[ "${confirm}" != "yes" ]] && {
    info "Cancelled."
    return 0
  }
  slack_api "auth.revoke" "POST" "bot" | pp
}

# ---------------------------------------------------------------------------
# App Manifest commands
# ---------------------------------------------------------------------------

cmd_app_create() {
  local manifest_file="${1:-}"
  [[ -z "${manifest_file}" ]] && die "Usage: $SCRIPT_NAME app-create <manifest.json|yaml>"
  [[ ! -f "${manifest_file}" ]] && die "Manifest file not found: ${manifest_file}"

  local manifest_json
  if [[ "${manifest_file}" == *.yaml || "${manifest_file}" == *.yml ]]; then
    command -v yq >/dev/null || die "yq is needed to convert YAML manifests"
    manifest_json="$(yq -o=json "${manifest_file}")"
  else
    manifest_json="$(cat "${manifest_file}")"
  fi

  echo "${manifest_json}" | jq -e . >/dev/null || die "Manifest is not valid JSON"

  local payload
  payload="$(jq -n --arg m "${manifest_json}" '{manifest: $m}')"

  info "Creating app from manifest..."
  local result
  result="$(slack_api "apps.manifest.create" "POST" "config" "${payload}")"
  echo "${result}" | pp

  local app_id
  app_id="$(echo "${result}" | jq -r '.app_id // empty')"
  if [[ -n "${app_id}" ]]; then
    info "App created. App ID: ${CYAN}${app_id}${NC}"
    info "Install it using the oauth_authorize_url from the response."
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

  warn "This will permanently delete app ${app_id}. Type 'yes' to confirm:"
  read -r confirm
  [[ "${confirm}" != "yes" ]] && {
    info "Cancelled."
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
    die "SLACK_CONFIG_REFRESH_TOKEN is required"
  fi

  info "Rotating config token..."
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
    info "New tokens received. Update your environment with:"
    echo -e "${GREEN}export SLACK_CONFIG_TOKEN=\"${new_token}\"${NC}"
    echo -e "${GREEN}export SLACK_CONFIG_REFRESH_TOKEN=\"${new_refresh}\"${NC}"
  fi
}

cmd_version() {
  echo "${SCRIPT_NAME} ${SCRIPT_VERSION}"
}

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
${BLUE}${SCRIPT_NAME}${NC} ${SCRIPT_VERSION} - Slack Bot and App Manager

Environment variables:
  SLACK_BOT_TOKEN              Bot token (xoxb-...)
  SLACK_CONFIG_TOKEN           App config token (xoxe.xoxp-...)
  SLACK_CONFIG_REFRESH_TOKEN   Refresh token for config token rotation
  SLACK_LOG_FILE               Optional log file path

Bot commands:
  auth-test
  post-message <channel> <text>
  post-blocks  <channel> <blocks.json>
  update-message <channel> <ts> <text>
  delete-message <channel> <ts>
  list-channels [types] [limit]
  create-channel <name> [true|false]
  channel-info <channel_id>
  list-users [limit]
  user-info <user_id>
  join-channel <channel_id>
  leave-channel <channel_id>
  upload-file <channels> <path> [title]
  set-presence <auto|away>
  presence-auto
  presence-away
  revoke-bot-token

App management:
  app-create   <manifest.json|yaml>
  app-update   <app_id> <manifest.json>
  app-delete   <app_id>
  app-export   <app_id>
  app-validate <manifest.json>
  rotate-config-token

Other:
  version
  help

Examples:
  export SLACK_BOT_TOKEN="xoxb-..."
  $SCRIPT_NAME auth-test
  $SCRIPT_NAME post-message C0123456789 "Hello"
  $SCRIPT_NAME set-presence away

  export SLACK_CONFIG_TOKEN="xoxe.xoxp-..."
  $SCRIPT_NAME app-create ./manifest.json

EOF
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
main() {
  mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true

  local cmd="${1:-}"
  shift || true

  case "${cmd}" in
  auth-test) cmd_auth_test "$@" ;;
  post-message) cmd_post_message "$@" ;;
  post-blocks) cmd_post_blocks "$@" ;;
  update-message) cmd_update_message "$@" ;;
  delete-message) cmd_delete_message "$@" ;;
  list-channels) cmd_list_channels "$@" ;;
  create-channel) cmd_create_channel "$@" ;;
  channel-info) cmd_channel_info "$@" ;;
  list-users) cmd_list_users "$@" ;;
  user-info) cmd_user_info "$@" ;;
  join-channel) cmd_join_channel "$@" ;;
  leave-channel) cmd_leave_channel "$@" ;;
  upload-file) cmd_upload_file "$@" ;;
  set-presence) cmd_set_presence "$@" ;;
  presence-auto) cmd_set_presence "auto" ;;
  presence-away) cmd_set_presence "away" ;;
  revoke-bot-token) cmd_revoke_bot_token "$@" ;;

  app-create) cmd_app_create "$@" ;;
  app-update) cmd_app_update "$@" ;;
  app-delete) cmd_app_delete "$@" ;;
  app-export) cmd_app_export "$@" ;;
  app-validate) cmd_app_validate "$@" ;;
  rotate-config-token) cmd_rotate_config_token "$@" ;;

  version | -v | --version) cmd_version ;;
  -h | --help | help | "")
    usage
    exit 0
    ;;
  *) die "Unknown command: ${cmd}. Try --help." ;;
  esac
}

main "$@"
