#!/bin/bash
set -e
workdir=$(pwd)
playbook=$(basename "${workdir}")
_docker_run_args=()

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
docker run -it --rm \
		-v "ansible-${playbook}:/root/.ansible" \
		-v "${workdir}:${workdir}" \
		--workdir="${workdir}" \
		"${_docker_run_args[@]}" \
	ghcr.io/soramitsukhmer-lab/deploy-shell:main
