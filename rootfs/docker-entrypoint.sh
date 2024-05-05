#!/bin/bash
export HOME="/overlayuser"
export ZSH_DISABLE_COMPFIX=true

echo "==> Provisioning group/user ${USER} with UID ${UID} and GID ${GID}..."
addgroup --system --verbose --gid ${GID} ${USER} || true
adduser --verbose --system --disabled-password --uid ${UID} --shell /bin/zsh --gid ${GID} --home "$HOME" ${USER}

echo "==> Setting up home directory..."
mkdir -p "$HOME"/{.config,.ssh}

echo "==> Linking /home/.zshrc to $HOME/.zshrc..."
ln -sf "/home/.zshrc" "$HOME/.zshrc"

# Execute the command as the specified user/group
exec s6-setuidgid $UID:$GID "$@"
