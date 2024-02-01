variable "ANSIBLE_VERSION" { default = "8.4.0" }
variable "ANSIBLE_LINT_VERSION" { default = "6.22.2" }

target "docker-metadata-action" {}
target "github-metadata-action" {}

target "template" {
  inherits = [
    "docker-metadata-action",
    "github-metadata-action",
  ]
  args = {
    ANSIBLE_VERSION = "${ANSIBLE_VERSION}"
    ANSIBLE_LINT_VERSION = "${ANSIBLE_LINT_VERSION}"
  }
}

target "default" {
  inherits = [
    "template",
  ]
  platforms = [
    "linux/amd64",
    "linux/arm64"
  ]
}

target "dev" {
  inherits = [
    "template",
  ]
  tags = [
    "soramitsukhmer-lab/deploy-shell:dev"
  ]
}
