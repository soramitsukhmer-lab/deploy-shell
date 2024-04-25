#!/bin/bash

DEPLOYSHELL_WORKDIR=$(pwd)
DEPLOYSHELL_PLAYBOOK=$(basename "${DEPLOYSHELL_WORKDIR}")

__SUPPORTED_VERSIONS=("dev", "main" "v8" "v9")
__DEPLOYSHELL_VERSION="${1:-main}"
__DEPLOYSHELL_IMAGE="${2:-ghcr.io/soramitsukhmer-lab/deploy-shell}"
if [[ ! " ${__SUPPORTED_VERSIONS[@]} " =~ " ${__DEPLOYSHELL_VERSION} " ]]; then
	echo "Unsupported deploy-shell version: ${__DEPLOYSHELL_VERSION}"
	echo "Supported versions: ${__SUPPORTED_VERSIONS[*]}"
	exit 1
fi

_DOCKER_CID_FILE="$HOME/.deploy-shell.cid"

_DOCKER_RUN_ARGS=(
	-v "ansible-${DEPLOYSHELL_PLAYBOOK}:/root/.ansible"
	-v "${DEPLOYSHELL_WORKDIR}:/overlayfs/${DEPLOYSHELL_WORKDIR}"
	--cidfile "$_DOCKER_CID_FILE"
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
echo "  Version: ${__DEPLOYSHELL_VERSION}"
echo "  Working directory: ${DEPLOYSHELL_WORKDIR}"
echo ""

echo ""
if [ -f "$_DOCKER_CID_FILE" ]; then
	echo "Reusing existing session..."
	docker exec -it $(cat "$_DOCKER_CID_FILE") zsh
	rm "$_DOCKER_CID_FILE"
else
	echo "Checking for updates..."
	docker pull ${__DEPLOYSHELL_IMAGE}:${__DEPLOYSHELL_VERSION}

	echo "Starting deploy-shell container..."
	docker run -it --rm "${_DOCKER_RUN_ARGS[@]}" ${__DEPLOYSHELL_IMAGE}:${__DEPLOYSHELL_VERSION}
fi

echo ""
echo "..............................."
echo "You have exited the virtual deployment shell!"
echo "Have a nice day!"
exit 0
