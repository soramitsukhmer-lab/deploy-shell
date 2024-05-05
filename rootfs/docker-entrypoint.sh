#!/bin/bash
export HOME="/home"
export ZSH_DISABLE_COMPFIX=true

echo "==> Provisioning group/user ${USER} with UID ${UID} and GID ${GID}..."
addgroup --system --verbose --gid ${GID} ${USER} || true
adduser --verbose --system --disabled-password --uid ${UID} --shell /bin/zsh --gid ${GID} --no-create-home --home "$HOME" ${USER}

echo "==> Setting up home directory..."
mkdir -p "$HOME"/.ssh

echo "==> Fixing permissions..."
chown -R $UID:$GID "$HOME"

# Execute the command as the specified user/group
exec s6-setuidgid $UID:$GID "$@"
