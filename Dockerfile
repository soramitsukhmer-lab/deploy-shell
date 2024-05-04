ARG PYTHON_IMAGE_TAG=3.11.5-slim
FROM python:${PYTHON_IMAGE_TAG}
SHELL [ "/bin/bash", "-c" ]

# Prerequisites
RUN --mount=type=bind,target=/tmp/src \
	--mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOT
	set -euxo pipefail
	cd /tmp/src
	export DEBIAN_FRONTEND=noninteractive
	echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
	mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean
	apt update
	xargs -a packages.debian apt install -qy
	chsh -s $(which zsh)
	rm /etc/apt/apt.conf.d/keep-cache
	mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean
EOT

# https://github.com/socheatsok78/s6-overlay-installer
ARG S6_OVERLAY_VERSION=v3.1.6.2
ARG S6_OVERLAY_INSTALLER=main/s6-overlay-installer-minimal.sh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/socheatsok78/s6-overlay-installer/${S6_OVERLAY_INSTALLER})"

# Install Ansible and Ansible Lint
ARG TARGETPLATFORM=linux/amd64
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION

RUN --mount=type=bind,target=/tmp/src \
	--mount=type=cache,target=/root/.cache/pip \
<<EOT
	cd /tmp/src
	python -m venv "/venv"
	source "/venv/bin/activate"
	set -euxo pipefail
	# Add piwheels repository
	if [ "${TARGETPLATFORM}" = "linux/arm/v7" ]; then
		echo "[global]" > /etc/pip.conf
		echo "extra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf;
	fi
	pip install --only-binary cryptography,ruamel.yaml.clib \
		ansible${ANSIBLE_VERSION:+>=$ANSIBLE_VERSION} \
		ansible-lint${ANSIBLE_LINT_VERSION:+>=$ANSIBLE_LINT_VERSION}
EOT

# https://ohmyz.sh/
RUN curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended

ADD rootfs /
ENTRYPOINT [ "/init-shim", "/docker-entrypoint.sh" ]
CMD [ "/bin/zsh" ]
WORKDIR /root
