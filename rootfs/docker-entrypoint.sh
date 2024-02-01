#!/bin/bash
source "/opt/soramitsukhmer/deploy-shell/venvrc"
source "/etc/ssh/sshagentrc"
exec "$@"
