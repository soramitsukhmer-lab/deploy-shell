ARG PYTHON_IMAGE_TAG=3.11.5-slim
FROM python:${PYTHON_IMAGE_TAG}

ADD rootfs /
SHELL [ "/bin/bash", "-c" ]

# Prerequisites
RUN --mount=type=bind,target=/tmp/mount \
	--mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	<<EOT
	set -euxo pipefail
	cd /tmp/mount
	export DEBIAN_FRONTEND=noninteractive
	echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
	mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean
	apt update
	xargs -a packages.debian apt install -qy
	rm /etc/apt/apt.conf.d/keep-cache
	mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean
EOT

# Install Ansible and Ansible Lint
ARG TARGETPLATFORM=linux/amd64
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
RUN --mount=type=cache,target=/root/.cache/pip \
	source /venvrc && \
	# Add piwheels repository
	if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then \
		echo "[global]" > /etc/pip.conf \
		&& echo "extra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf; \
	fi && \
	pip install --only-binary cryptography,ruamel.yaml.clib \
		ansible${ANSIBLE_VERSION:+==$ANSIBLE_VERSION} \
		ansible-lint${ANSIBLE_LINT_VERSION:+==$ANSIBLE_LINT_VERSION}

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "/bin/zsh" ]
