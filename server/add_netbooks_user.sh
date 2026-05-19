#!/bin/bash
# Add (or remove) a GitHub user to the netbooks allow-list in S3.
# Picked up by the jhub authenticator within 5 min — no restart needed.
#
# Usage:
#   add_netbooks_user.sh add <github-username>
#   add_netbooks_user.sh remove <github-username>
#   add_netbooks_user.sh list

set -euo pipefail

# Use ubuntu's AWS creds even when invoked via `sudo` (sudo strips HOME).
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-/home/ubuntu/.aws/credentials}"
export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-/home/ubuntu/.aws/config}"

BUCKET="netzoo"
KEY="netbooks/netbooks_allowed_users.csv"
S3="s3://$BUCKET/$KEY"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

action="${1:-help}"
user="${2:-}"

case "$action" in
  add)
    [[ -z "$user" ]] && { echo "usage: $0 add <github-username>"; exit 2; }
    aws s3 cp "$S3" "$TMP" >/dev/null
    if grep -q -i "^$user\$" "$TMP"; then
      echo "already in allow-list: $user"
      exit 0
    fi
    # If the previous last line lacks a trailing newline, append one first.
    if [[ -s "$TMP" ]] && [[ "$(tail -c 1 "$TMP" | od -An -c | tr -d ' ')" != $'\\n' ]]; then
      printf '\n' >> "$TMP"
    fi
    printf '%s\n' "$user" >> "$TMP"
    aws s3 cp "$TMP" "$S3" >/dev/null
    n=$(($(wc -l < "$TMP") - 1))
    echo "added $user ($n users total). They can log in within ~5 min."
    ;;
  remove)
    [[ -z "$user" ]] && { echo "usage: $0 remove <github-username>"; exit 2; }
    aws s3 cp "$S3" "$TMP" >/dev/null
    if ! grep -q -i "^$user\$" "$TMP"; then
      echo "not in allow-list: $user"
      exit 0
    fi
    grep -v -i "^$user\$" "$TMP" > "$TMP.new" && mv "$TMP.new" "$TMP"
    aws s3 cp "$TMP" "$S3" >/dev/null
    echo "removed $user. Existing session may still work until next jhub restart."
    ;;
  list)
    aws s3 cp "$S3" "$TMP" >/dev/null
    tail -n +2 "$TMP" | sort
    ;;
  *)
    cat <<EOF
usage:
  $0 add <github-username>     - add user to the netbooks allow-list
  $0 remove <github-username>  - remove user
  $0 list                      - list current users (sorted)

Picked up by jupyterhub within 5 min via the S3-cached authenticator.
EOF
    exit 2
    ;;
esac
