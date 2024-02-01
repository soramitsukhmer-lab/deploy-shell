#!/bin/bash
set -e
workdir=$(pwd)
playbook=$(basename "${workdir}")

_supported_versions=("main" "v8" "v9")
_deploy_shell_version="${1:-main}"
if [[ ! " ${_supported_versions[@]} " =~ " ${_deploy_shell_version} " ]]; then
	echo "Unsupported deploy-shell version: ${_deploy_shell_version}"
	echo "Supported versions: ${_supported_versions[*]}"
	exit 1
fi

_docker_run_args=(
	-v "ansible-${playbook}:/root/.ansible"
	-v "${workdir}:/overlayfs/${workdir}"
	--workdir="/overlayfs/${workdir}"
)

# Mount ".ssh" directory locate in the host HOME directory.
# If the playbook directory contains a ".ssh" directory, it will take precedence
if [ -d "${workdir}.ssh" ]; then
	_docker_run_args+=(-v "${workdir}.ssh:/root/.ssh:ro")
elif [ -d "$HOME/.ssh" ]; then
	_docker_run_args+=(-v "$HOME/.ssh:/root/.ssh:ro")
fi

echo "Starting deploy-shell container..."
echo " - Working directory: ${workdir}"
echo " - Playbook: ${playbook}"
echo ""
set -x
docker run -it --rm "${_docker_run_args[@]}" \
	ghcr.io/soramitsukhmer-lab/deploy-shell:${_deploy_shell_version}
