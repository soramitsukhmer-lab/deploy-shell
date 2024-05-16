#!/usr/bin/env bash

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

log() {
	printf "%s\n" "$(chomp "$1")"
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

DEPLOYSHELL_ROOT="$HOME/.deploy-shell"
DEPLOYSHELL_DEFAULT_IMAGE="ghcr.io/soramitsukhmer-lab/deploy-shell:main"
DEPLOYSHELL_IMAGE_SUPPORTED_VERSIONS=("main" "v8" "v9")

function main() {
	local input_image_tag=${1:-$DEPLOYSHELL_DEFAULT_IMAGE}

	local container_image_name=$(echo $input_image_tag | cut -d ':' -f 1)
	local container_image_version=$(echo $input_image_tag | cut -d ':' -f 2)
	local container_skip_update=${SKIP_UPDATE:-"false"}

	# Check if the container_image_version is dev or develop
	if [[ "${container_image_version}" == "dev" ]] || [[ "${container_image_version}" == "develop" ]]; then
		if [[ -z "${SKIP_UPDATE}" ]]; then
			container_skip_update="true"
		fi
	else
		if [[ ! " ${DEPLOYSHELL_IMAGE_SUPPORTED_VERSIONS[@]} " =~ " ${container_image_version} " ]]; then
			error "The image version ${container_image_version} is not supported. Supported versions are: ${DEPLOYSHELL_IMAGE_SUPPORTED_VERSIONS[@]}"
			exit 1
		fi
	fi

	# Print welcome message
	ohai "Welcome to the Virtual Deployment Shell environment!"

	# check container_skip_update
	if [[ "${container_skip_update}" == "false" ]]; then
		ohai "Pulling the latest image from ${container_image_name}:${container_image_version}"
		execute docker pull ${container_image_name}:${container_image_version}
	fi

	local project_dir="$(pwd)"
	local project_name=$(basename $project_dir)
	local project_manifest_dir="$DEPLOYSHELL_ROOT/$project_name"
	local project_force_recreate=${FORCE_RECREATE:-"false"}

	# Create the deploy-shell root directory
	execute mkdir -p "$DEPLOYSHELL_ROOT"

	# create deploy-shell project directory
	if [[ "${project_force_recreate}" == "true" ]]; then
		ohai "Re-creating the project directory: $project_manifest_dir"
		execute rm -rf "$project_manifest_dir"
	elif [[ ! -d "$project_manifest_dir" ]]; then
		ohai "Creating the project directory: $project_manifest_dir"
	fi
	execute mkdir -p "$project_manifest_dir"

	# Start the container
	local container_id_file="$project_manifest_dir/container_id"
	local container_homedir="/home"
	local container_workdir="/workdir"

	# Check if the container is already running
	if [ -f "$container_id_file" ]; then
		local container_id=$(cut -c 1-8 $container_id_file)
		warn "A other session for \"$project_name\" is already running."
		warn "You can connect to the running container by running: docker exec -it ${container_id} connect"
		warn "Or stop the container by running: docker stop ${container_id}"
		exit 1
	fi

	# Prepare the container run arguments
	local container_run_args=(
		--cidfile "${container_id_file}"
		--env "USER=$(whoami)"
		--env "UID=$(id -u)"
		--env "GID=$(id -g)"
		--workdir "${container_workdir}"
		-v "$project_dir:${container_workdir}"
		-v "deploy-shell-ansible-$project_name:$container_homedir/.ansible"
	)

	# Inherit GitHub credentials
	if [ "$(command -v gh)" ]; then
		local gh_auth_token=$(gh auth token)
		if [[ -n "${gh_auth_token}" ]]; then
			ohai "Found GitHub credentials. Passing to the container..."
			container_run_args+=(-e "GH_TOKEN=${gh_auth_token}")
		fi
	fi

	# Run the container
	ohai "Running the virtual deployment environment using: ${container_image_name}:${container_image_version}"
	(set -x; docker run -it --rm "${container_run_args[@]}" "${input_image_tag}")
	if [ $? -eq 0 ]; then
		ohai "Deploy-shell container exited successfully!"
	else
		error "Deploy-shell container exited! (code: $?)"
	fi

	# Clean up project
	ohai "Cleaning up the project directory: $project_manifest_dir"
	execute rm -rf "$project_manifest_dir"
}

main "$@"
