#!/bin/bash
# Remove /run/jupyter-<user>-singleuser entries left behind by a previous
# JupyterHub session whose singleuser unit is no longer running.
# systemdspawner 1.0.1 trips with FileExistsError on dangling symlinks
# from /run, so we sweep them before the hub starts.
set -u
shopt -s nullglob
for link in /run/jupyter-*-singleuser; do
    user=$(basename "$link" | sed 's/^jupyter-//; s/-singleuser$//')
    if ! systemctl is-active --quiet "jupyter-${user}-singleuser.service"; then
        rm -rf "$link" "/run/private/jupyter-${user}-singleuser"
    fi
done
