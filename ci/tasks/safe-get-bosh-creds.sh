#!/bin/bash

safe -k target ci ${VAULT_TARGET:?required}
echo ${GITHUB_TOKEN:?required} | safe auth github

safe get ${VAULT_PREFIX:?required}

cat director_creds/env > <<-YAML
export BOSH_ENVIRONMENT=https://10.58.111.4:25555
export BOSH_CA_CERT=$(safe get secret/microbosh/vsphere/prod/certs:rootCA.key)
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(safe get secret/microbosh/vsphere/prod/users:admin_password)
YAML
