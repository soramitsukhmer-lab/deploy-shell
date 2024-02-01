# About
A virtual deployment shell for DevOps for @soramitsukhmer. Simplify the process of using Ansible and other tools for DevOps

## Features

- Python `v3.11.5`
- Ansible `v8` and `v9`

See `packages.debian` file for a list of installed packages.

## Usage

By default, the script will install the latest version of the deployment shell.

```sh
bash -c "$(curl -fsSL https://soramitsukhmer-lab.github.io/deploy-shell/run.sh)"
```

Or, you can specify a version:

```sh
bash -c "$(curl -fsSL https://soramitsukhmer-lab.github.io/deploy-shell/run.sh)" -- v8 # or v9
```

## License
Licensed under the [Apache License, Version 2.0](LICENSE).
