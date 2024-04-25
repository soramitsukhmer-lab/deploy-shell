#!/bin/bash

DEPLOYSHELL_WORKDIR=$(pwd)
DEPLOYSHELL_PLAYBOOK=$(basename "${DEPLOYSHELL_WORKDIR}")

_SUPPORTED_VERSIONS=("main" "v8" "v9")
_DEPLOYSHELL_VERSION="${1:-main}"
_DEPLOYSHELL_IMAGE="${2:-ghcr.io/soramitsukhmer-lab/deploy-shell}"
if [[ ! " ${_SUPPORTED_VERSIONS[@]} " =~ " ${_DEPLOYSHELL_VERSION} " ]]; then
	echo "Unsupported deploy-shell version: ${_DEPLOYSHELL_VERSION}"
	echo "Supported versions: ${_SUPPORTED_VERSIONS[*]}"
	exit 1
fi

_DOCKER_CID_FILE="$HOME/.deploy-shell.cid"

_DOCKER_RUN_ARGS=(
	--cidfile "$_DOCKER_CID_FILE"
	-v "ansible-${DEPLOYSHELL_PLAYBOOK}:/root/.ansible"
	-v "${DEPLOYSHELL_WORKDIR}:/overlayfs/${DEPLOYSHELL_WORKDIR}"
	--workdir="/overlayfs/${DEPLOYSHELL_WORKDIR}"
)

# Mount ".ssh" directory locate in the host HOME directory.
# If the playbook directory contains a ".ssh" directory, it will take precedence
if [ -d "${DEPLOYSHELL_WORKDIR}.ssh" ]; then
	_DOCKER_RUN_ARGS+=(-v "${DEPLOYSHELL_WORKDIR}.ssh:/root/.ssh:ro")
elif [ -d "$HOME/.ssh" ]; then
	_DOCKER_RUN_ARGS+=(-v "$HOME/.ssh:/root/.ssh:ro")
fi

echo "Welcome to @soramitsukhmer-lab/deploy-shell!"
echo ""
echo "A virtual deployment shell for DevOps for @soramitsukhmer"
echo "Simplify the process of using Ansible and other tools for DevOps"
echo ""
echo "  Version: ${_DEPLOYSHELL_VERSION}"
echo "  Working directory: ${DEPLOYSHELL_WORKDIR}"
echo ""

echo "Checking for updates..."
docker pull ${_DEPLOYSHELL_IMAGE}:${_DEPLOYSHELL_VERSION}

echo ""
echo "Starting deploy-shell container..."
if [ -f "$_DOCKER_CID_FILE" ]; then
	docker exec -it $(cat "$_DOCKER_CID_FILE") zsh
else
	docker run -it --rm "${_DOCKER_RUN_ARGS[@]}" ${_DEPLOYSHELL_IMAGE}:${_DEPLOYSHELL_VERSION}
fi

echo ""
echo "..............................."
echo "You have exited the virtual deployment shell!"
echo "Have a nice day!"
exit 0
