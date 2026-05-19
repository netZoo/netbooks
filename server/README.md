# Production server config

These are the files that run the public JupyterHub at
[netbooks.networkmedicine.org](https://netbooks.networkmedicine.org).
They live on the production EC2 host at the paths in the table below;
this directory is the source of truth, mirror it back to the host on
change.

Local-development users running netbooks via Vagrant should look at
[`../vagrant/`](../vagrant/) instead.

| File in this dir | Path on EC2 |
|---|---|
| `jupyterhub.service` | `/etc/systemd/system/jupyterhub.service` |
| `jupyterhub_config.py` | `/home/ubuntu/jupyterhub_config.py` |
| `start_jupyterhub.sh` | `/home/ubuntu/start_jupyterhub.sh` (legacy; superseded by systemd unit but kept for manual debugging) |
| `add_netbooks_user.sh` | `/usr/local/bin/add_netbooks_user.sh` |
| `backup_jupyterhub_db.sh` | `/usr/local/bin/backup_jupyterhub_db.sh` (cron `/etc/cron.d/jupyterhub-backup` at 02:30 UTC daily) |
| `le-restart-jupyterhub.sh` | `/etc/letsencrypt/renewal-hooks/deploy/restart-jupyterhub.sh` |
| `.netbooks_env.example` | template for `/home/ubuntu/.netbooks_env` (root:root 0400) |

## Operational basics

```bash
# Service control (replaces the old manual "nohup jupyterhub &" workflow)
sudo systemctl status jupyterhub
sudo systemctl restart jupyterhub
sudo journalctl -u jupyterhub -f          # live logs

# Add a GitHub user to the allow-list (S3-backed CSV; picked up within 5 min)
add_netbooks_user.sh add <github-username>
add_netbooks_user.sh remove <github-username>
add_netbooks_user.sh list

# Manual backup (cron does this nightly)
/usr/local/bin/backup_jupyterhub_db.sh
```

## Secrets

`GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` live in
`/home/ubuntu/.netbooks_env` (root:root, mode 0400). The systemd unit
loads them via `EnvironmentFile=`. The file is **not** tracked in
git — only `.netbooks_env.example` is.

Future improvement: migrate to AWS SSM Parameter Store or Secrets
Manager. Blocked today on the IAM user `benguebila@hsph.harvard.edu`
lacking `ssm:*` / `secretsmanager:*` permissions.

## Allow-list

The allow-list is a CSV at `s3://netzoo/netbooks/netbooks_allowed_users.csv`.
The `S3CachedLocalGitHubOAuthenticator` subclass defined inside
`jupyterhub_config.py` re-fetches it on each login with a 5-minute TTL,
so adding a user no longer requires a hub restart.

## Backups

Daily tarballs of `jupyterhub.sqlite`, `jupyterhub_cookie_secret`, and
`jupyterhub_config.py` are uploaded to
`s3://netzoo/netbooks/backups/jhub-backup-YYYYMMDD-HHMMSS.tgz` (plus a
rolling `latest.tgz`). Anything older than 30 days is pruned.

To restore: `aws s3 cp s3://netzoo/netbooks/backups/latest.tgz -` and
unpack into `/home/ubuntu/`.

## TLS

Let's Encrypt cert at `/etc/letsencrypt/live/netbooks.networkmedicine.org/`.
Auto-renewal: `snap.certbot.renew.timer`. The deploy hook in
`/etc/letsencrypt/renewal-hooks/deploy/restart-jupyterhub.sh` restarts
the JupyterHub service when the cert is renewed, so HTTPS picks up the
new cert without manual intervention.
