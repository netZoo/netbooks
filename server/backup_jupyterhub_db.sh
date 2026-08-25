#!/bin/bash
# Daily backup of jupyterhub.sqlite (and cookie_secret) to s3://netzoo/netbooks/backups/.
# Keeps 30 days of versions via S3 date-stamped key. Run via cron.

set -euo pipefail

# AWS creds — same trick as add_netbooks_user.sh so the cron user works.
export AWS_SHARED_CREDENTIALS_FILE="${AWS_SHARED_CREDENTIALS_FILE:-/home/ubuntu/.aws/credentials}"
export AWS_CONFIG_FILE="${AWS_CONFIG_FILE:-/home/ubuntu/.aws/config}"

BUCKET="netzoo"
PREFIX="netbooks/backups"
TS=$(date -u +%Y%m%d-%H%M%S)
LOG=/var/log/jupyterhub-backup.log
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

log() { echo "[$(date -u +%FT%TZ)] $*" >> "$LOG"; }

log "starting backup ts=$TS"

# Snapshot sqlite via .backup so we don't copy a half-written file
sqlite3 /home/ubuntu/jupyterhub.sqlite ".backup '$TMPDIR/jupyterhub.sqlite'"
cp /home/ubuntu/jupyterhub_cookie_secret "$TMPDIR/jupyterhub_cookie_secret"
cp /home/ubuntu/jupyterhub_config.py "$TMPDIR/jupyterhub_config.py"

# Tarball + upload
tar -C "$TMPDIR" -czf "$TMPDIR/jhub-backup-$TS.tgz" \
    jupyterhub.sqlite jupyterhub_cookie_secret jupyterhub_config.py
aws s3 cp "$TMPDIR/jhub-backup-$TS.tgz" "s3://$BUCKET/$PREFIX/jhub-backup-$TS.tgz" \
    --storage-class STANDARD_IA --quiet

# Drop a "latest" pointer for easy restore
aws s3 cp "$TMPDIR/jhub-backup-$TS.tgz" "s3://$BUCKET/$PREFIX/latest.tgz" --quiet

# Prune backups older than 30 days
cutoff=$(date -u -d '30 days ago' +%Y%m%d || date -u -v-30d +%Y%m%d)
aws s3 ls "s3://$BUCKET/$PREFIX/" \
  | awk '{print $4}' \
  | grep -E '^jhub-backup-[0-9]{8}-[0-9]{6}\.tgz$' \
  | while read -r key; do
      keyts=$(echo "$key" | sed -E 's/^jhub-backup-([0-9]{8})-.*/\1/')
      if [[ "$keyts" < "$cutoff" ]]; then
        log "pruning $key (older than $cutoff)"
        aws s3 rm "s3://$BUCKET/$PREFIX/$key" --quiet
      fi
    done

log "done ts=$TS"
