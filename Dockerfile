ARG PYTHON_IMAGE_TAG=3.11.5-alpine
FROM python:${PYTHON_IMAGE_TAG}

ARG TARGETPLATFORM
ARG ANSIBLE_VERSION
ARG ANSIBLE_LINT_VERSION

# Add piwheels repository
RUN if [ "${TARGETPLATFORM:-linux/amd64}" = "linux/arm/v7" ]; then \
		echo "[global]" > /etc/pip.conf \
		&& echo "extra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf; \
	fi

# Install Python packages
RUN export PYTHONUNBUFFERED=1 && \
	pip install --no-cache-dir --only-binary cryptography,ruamel.yaml.clib \
	ansible${ANSIBLE_VERSION:+==$ANSIBLE_VERSION} \
	ansible-lint${ANSIBLE_LINT_VERSION:+==$ANSIBLE_LINT_VERSION}
