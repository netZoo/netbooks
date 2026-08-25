#!/bin/bash
# Start JupyterHub with the GitHub OAuth env vars set.
# Run from /home/ubuntu (where jupyterhub_config.py + sqlite + cookie_secret live).
#
# Usage:
#   sudo ./start_jupyterhub.sh         # start in background
#   sudo ./start_jupyterhub.sh stop    # stop
#   sudo ./start_jupyterhub.sh restart # stop+start

set -u

CFG=/home/ubuntu/jupyterhub_config.py
LOG=/home/ubuntu/jupyterhub.log
HUB=/opt/conda/envs/netbooks/bin/jupyterhub
ENVFILE=/home/ubuntu/.netbooks_env

# GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET are read from /home/ubuntu/.netbooks_env
# (chmod 600). Falls back to inherited env so you can also export them ad hoc.
if [[ -f "$ENVFILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENVFILE"
  set +a
fi

cmd="${1:-start}"

stop_hub() {
  local pid
  pid=$(pgrep -f "jupyterhub -f $CFG" || true)
  if [[ -n "$pid" ]]; then
    echo "stopping jupyterhub (pid $pid)..."
    kill "$pid"
    sleep 2
    pkill -9 -f "jupyterhub -f $CFG" 2>/dev/null || true
  fi
  pkill -9 -f "configurable-http-proxy" 2>/dev/null || true
}

start_hub() {
  if pgrep -f "jupyterhub -f $CFG" >/dev/null; then
    echo "already running (pid $(pgrep -f "jupyterhub -f $CFG"))"
    return 0
  fi
  : "${GITHUB_CLIENT_ID:?set GITHUB_CLIENT_ID in $ENVFILE}"
  : "${GITHUB_CLIENT_SECRET:?set GITHUB_CLIENT_SECRET in $ENVFILE}"
  cd /home/ubuntu
  # AWS_SHARED_CREDENTIALS_FILE / HOME are needed so the S3-cached
  # authenticator (running as root) can read ubuntu's AWS credentials.
  nohup env \
    GITHUB_CLIENT_ID="$GITHUB_CLIENT_ID" \
    GITHUB_CLIENT_SECRET="$GITHUB_CLIENT_SECRET" \
    HOME=/home/ubuntu \
    AWS_SHARED_CREDENTIALS_FILE=/home/ubuntu/.aws/credentials \
    AWS_CONFIG_FILE=/home/ubuntu/.aws/config \
    AWS_DEFAULT_REGION=us-east-1 \
    "$HUB" -f "$CFG" >> "$LOG" 2>&1 &
  sleep 3
  if pgrep -f "jupyterhub -f $CFG" >/dev/null; then
    echo "started; log: $LOG"
  else
    echo "FAILED; last lines of $LOG:"
    tail -20 "$LOG"
    exit 1
  fi
}

case "$cmd" in
  start)   start_hub ;;
  stop)    stop_hub ;;
  restart) stop_hub; start_hub ;;
  status)
    pgrep -fa "jupyterhub -f $CFG" || echo "not running"
    ;;
  *)
    echo "usage: $0 {start|stop|restart|status}"
    exit 2
    ;;
esac
