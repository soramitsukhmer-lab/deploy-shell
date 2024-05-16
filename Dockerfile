ARG PYTHON_IMAGE_TAG=3.11.5-slim
FROM python:${PYTHON_IMAGE_TAG}

# Change default shell to bash
SHELL [ "/bin/bash", "-c" ]

# Prerequisites
RUN --mount=type=bind,target=/tmp/src \
	--mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
<<EOT
	set -euxo pipefail
	cd /tmp/src
	export DEBIAN_FRONTEND=noninteractive
	mkdir -p -m 755 /etc/apt/keyrings
	# Enable APT caching
	echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
	mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean

	# Install wget if not available
	(type -p wget >/dev/null || (apt update && apt-get install wget -y))

	# Configure GitHub CLI repository
	wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
	chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	
	# Install packages
	apt update
	xargs -a packages.debian apt install -qy
	apt install gh -y
	chsh -s $(which zsh)

	# Fix potential UTF-8 errors with ansible-test.
	locale-gen en_US.UTF-8

	# Remove Python externally managed environment
	PYTHON_VERSION=$(python3 --version | awk '{split($2, a, "."); print a[1] "." a[2]}')
	rm -rf /usr/lib/python${PYTHON_VERSION}/EXTERNALLY-MANAGED

	# https://ohmyz.sh/
	curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | ZSH=/home/.oh-my-zsh bash -s -- --unattended

	# Reverse changes to APT caching
	rm /etc/apt/apt.conf.d/keep-cache
	mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean
EOT


# Install Ansible and Ansible Lint
ARG TARGETPLATFORM=linux/amd64
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION
RUN --mount=type=bind,target=/tmp/src \
	--mount=type=cache,target=/root/.cache/pip \
<<EOT
	cd /tmp/src
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

# https://github.com/socheatsok78/s6-overlay-installer
ARG S6_OVERLAY_VERSION=v3.1.6.2
ARG S6_OVERLAY_INSTALLER=main/s6-overlay-installer-minimal.sh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/socheatsok78/s6-overlay-installer/${S6_OVERLAY_INSTALLER})"
ADD rootfs /
ENTRYPOINT [ "/init-shim", "/docker-entrypoint.sh" ]
CMD [ "/bin/zsh" ]
WORKDIR /root
