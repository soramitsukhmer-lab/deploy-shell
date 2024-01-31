#!/bin/bash
set -e
_playbook=$(basename `pwd`)
docker run -it --rm \
		-v "ansible-${_playbook}:/root/.ansible" \
		-v "$(pwd):$(pwd)" \
		--workdir="$(pwd)" \
	ghcr.io/soramitsukhmer-lab/deploy-shell:main
