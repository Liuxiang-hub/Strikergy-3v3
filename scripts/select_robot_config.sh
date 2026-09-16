#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
IDENTITY_FILE="${STRIKERGY_ROBOT_ID_FILE:-${WORKSPACE_ROOT}/.robot_identity}"

identity="${STRIKERGY_ROBOT_ID:-}"
if [[ -z "${identity}" && -r "${IDENTITY_FILE}" ]]; then
    identity="$(tr -d '\000\r\n[:space:]' < "${IDENTITY_FILE}")"
fi

case "${identity}" in
    *60035) serial_suffix="60035" ;;
    *60023) serial_suffix="60023" ;;
    "")
        echo "[ROBOT IDENTITY ERROR] Missing ${IDENTITY_FILE}." >&2
        echo "Provision this robot once with its registered serial suffix (60035 or 60023)." >&2
        exit 20
        ;;
    *)
        echo "[ROBOT IDENTITY ERROR] Unknown robot identity: ${identity}" >&2
        echo "Refusing to start so two robots cannot use the same player_id." >&2
        exit 21
        ;;
esac

profile="${WORKSPACE_ROOT}/configs/robots/${serial_suffix}.conf"
if [[ ! -r "${profile}" ]]; then
    echo "[ROBOT IDENTITY ERROR] Missing profile: ${profile}" >&2
    exit 22
fi

read_profile_value() {
    local key="$1"
    awk -F= -v wanted="${key}" '$1 == wanted { print $2; exit }' "${profile}"
}

profile_suffix="$(read_profile_value serial_suffix)"
player_id="$(read_profile_value player_id)"
player_role="$(read_profile_value player_role)"

if [[ "${profile_suffix}" != "${serial_suffix}" ]]; then
    echo "[ROBOT IDENTITY ERROR] Profile serial mismatch in ${profile}." >&2
    exit 23
fi
if [[ ! "${player_id}" =~ ^[1-3]$ ]]; then
    echo "[ROBOT IDENTITY ERROR] Invalid player_id in ${profile}: ${player_id}" >&2
    exit 24
fi
case "${player_role}" in
    striker|supporter|keeper) ;;
    *)
        echo "[ROBOT IDENTITY ERROR] Invalid player_role in ${profile}: ${player_role}" >&2
        exit 25
        ;;
esac

if [[ "${1:-}" == "--values" ]]; then
    printf '%s %s %s\n' "${serial_suffix}" "${player_id}" "${player_role}"
else
    printf 'Robot %s -> player_id=%s, player_role=%s\n' \
        "${serial_suffix}" "${player_id}" "${player_role}"
fi
