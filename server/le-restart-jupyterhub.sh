#!/bin/bash
# Restart JupyterHub when Let's Encrypt renews the cert so the HTTPS
# proxy picks up the new cert.
# Invoked by certbot via /etc/letsencrypt/renewal-hooks/deploy/.
if [ "$RENEWED_LINEAGE" = "/etc/letsencrypt/live/netbooks.networkmedicine.org" ]; then
    /bin/systemctl restart jupyterhub.service
fi
