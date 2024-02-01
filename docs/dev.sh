#!/bin/bash
workdir=$(pwd)
playbook=$(basename "${workdir}")

_supported_versions=("dev" "main" "v8" "v9")
_deploy_shell_version="${1:-dev}"
_deploy_shell_image="${2:-soramitsukhmer-lab/deploy-shell}"
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

echo "Welcome to @soramitsukhmer-lab/deploy-shell!"
echo ""
echo "A virtual deployment shell for DevOps for @soramitsukhmer"
echo "Simplify the process of using Ansible and other tools for DevOps"
echo ""
echo "  Version: ${_deploy_shell_version}"
echo "  Working directory: ${workdir}"
echo ""

echo "Checking for updates..."
docker pull \
	${_deploy_shell_image}:${_deploy_shell_version}

echo ""
echo "Starting deploy-shell container..."
docker run -it --rm "${_docker_run_args[@]}" \
	${_deploy_shell_image}:${_deploy_shell_version}

echo ""
echo "..............................."
echo "You have exited the virtual deployment shell!"
echo "Have a nice day!"
exit 0
