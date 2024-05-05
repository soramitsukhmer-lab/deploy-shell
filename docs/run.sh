#!/usr/bin/env bash

DEPLOYSHELL_ROOT="$HOME/.deploy-shell"
DEPLOYSHELL_CONTAINER_TAG="ghcr.io/soramitsukhmer-lab/deploy-shell:main"
DEPLOYSHELL_SUPPORTED_VERSIONS=("main" "v8" "v9")

# helpers
# string formatters
if [[ -t 1 ]]; then
	tty_escape() { printf "\033[%sm" "$1"; }
else
	tty_escape() { :; }
fi

tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_yellow="$(tty_mkbold 33)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
	local arg
	printf "%s" "$1"
	shift
	for arg in "$@"; do
		printf " "
		printf "%s" "${arg// /\ }"
	done
}

chomp() {
	printf "%s" "${1/"$'\n'"/}"
}

ohai() {
	printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
	printf "${tty_yellow}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

error(){
	printf "${tty_red}Error${tty_reset}: %s\n" "$(chomp "$1")" >>/dev/stderr
}

abort() {
  printf "%s\n" "$1"
  exit 1
}

execute() {
  if ! "$@"; then
	abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

function print_welcome() {
	ohai "Welcome to @soramitsukhmer-lab/deploy-shell!"
	ohai ""
	ohai "A virtual deployment shell for DevOps for @soramitsukhmer"
	ohai "Simplify the process of using Ansible and other tools for DevOps"
}

function print_options() {
	ohai ""
}

function main() {
	local INPUT_VERSION=${1:-"main"}
	local INPUT_CONTAINER_TAG=$2

	local DEPLOYSHELL_PWD=$(pwd)
	local DEPLOYSHELL_WORKDIR=$(basename "${DEPLOYSHELL_PWD}")
	local DEPLOYSHELL_CID="$DEPLOYSHELL_ROOT/current"

	# Check input version
	if [[ -z "${INPUT_CONTAINER_TAG}" ]]; then
		if [[ ! " ${DEPLOYSHELL_SUPPORTED_VERSIONS[@]} " =~ " ${INPUT_VERSION} " ]]; then
			error "Unsupported version: ${INPUT_VERSION}, supported versions: ${DEPLOYSHELL_SUPPORTED_VERSIONS[*]}"
			exit 2
		fi
	else
		DEPLOYSHELL_CONTAINER_TAG="${INPUT_CONTAINER_TAG}:${INPUT_VERSION}"
	fi

	# Print welcome message
	print_welcome
	echo ""

	# Do pre-cleanup if needed
	if [[ -n "${DEPLOYSHELL_FORCE_CLEANUP}" ]]; then
		deployshell_stop
		deployshell_cleanup
	fi

	# Check if the deploy-shell root directory exists
	execute mkdir -p "${DEPLOYSHELL_ROOT}"

	# Check if the deploy-shell container ID file exists
	# If it exists, connect to the existing session
	# Otherwise, check for updates and start a new session
	if [ -f "${DEPLOYSHELL_CID}" ]; then
		ohai "Connecting to existing session..."
		execute docker exec -it $(cat "${DEPLOYSHELL_CID}") zsh
	else
		local DOCKER_USER_HOME="/home"
		local DOCKER_PROJECT_HOME="/workdir"
		local DOCKER_RUN_ARGS=(
			--env "USER=$(whoami)"
			--env "UID=$(id -u)"
			--env "GID=$(id -g)"
			--cidfile "${DEPLOYSHELL_CID}"
			--workdir "$DOCKER_PROJECT_HOME/${DEPLOYSHELL_WORKDIR}"
			-v "${DEPLOYSHELL_PWD}:$DOCKER_PROJECT_HOME/${DEPLOYSHELL_WORKDIR}"
			-v "deploy-shell-ansible-${DEPLOYSHELL_WORKDIR}:$DOCKER_USER_HOME/.ansible"
		)

		ohai "Prepare container environment..."

		# Inherit GitHub credentials
		if [ "$(command -v gh)" ]; then
			GITHUB_AUTH_TOKEN=$(gh auth token)
			if [[ -n "${GITHUB_AUTH_TOKEN}" ]]; then
				ohai "Inherit GitHub credentials..."
				DOCKER_RUN_ARGS+=(-e "GH_TOKEN=${GITHUB_AUTH_TOKEN}")
			fi
		fi
		
		# Linking user ~/.gitconfig
		if [ -f "$HOME/.gitconfig" ]; then
			ohai "Linking user $HOME/.gitconfig..."
			DOCKER_RUN_ARGS+=(-v "$HOME/.gitconfig:${DOCKER_USER_HOME}/.gitconfig:ro")
		fi

		# Check for updates
		if [[ -z "$DEPLOYSHELL_SKIP_UPDATE" ]]; then
			ohai "Check for updates..."
			execute docker pull "${DEPLOYSHELL_CONTAINER_TAG}"
		fi

		ohai "Starting deploy-shell container..."
		echo "$ docker run -it --rm ${DOCKER_RUN_ARGS[@]}"
		echo ""
		docker run -it --rm "${DOCKER_RUN_ARGS[@]}" "${DEPLOYSHELL_CONTAINER_TAG}"
		warn "Deploy-shell container exited! (code: $?)"
		# if [[ $? -ne 0 ]] && [[ $? -ne 130 ]]; then
		# 	error "Failed to start deploy-shell container!"
		# 	exit 3
		# fi
	fi
}

function deployshell_stop() {
	if [ -f "$DEPLOYSHELL_CID" ]; then
		(cat "${DEPLOYSHELL_CID}" | xargs docker kill -s SIGTERM) >/dev/null
		(cat "${DEPLOYSHELL_CID}" | xargs docker rm -f) >/dev/null
	fi
	
}
function deployshell_cleanup {
	if [ -d "$DEPLOYSHELL_ROOT" ]; then
		rm -rf "${DEPLOYSHELL_ROOT}" >/dev/null || true
	fi
}

function tran_EXIT() {
	deployshell_cleanup
	exit 0
}

function tran_SIGHUP() {
	deployshell_stop
	deployshell_cleanup
	exit 0
}

trap tran_EXIT EXIT
trap tran_SIGHUP HUP
main "$@"
