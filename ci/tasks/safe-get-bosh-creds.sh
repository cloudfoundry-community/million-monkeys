#!/bin/bash

safe -k target ci ${VAULT_TARGET:?required}
echo ${GITHUB_TOKEN:?required} | safe auth github

: ${VAULT_PREFIX:?required}

export BOSH_IP=$(safe get ${VAULT_PREFIX}/env:ip)
safe get ${VAULT_PREFIX}/certs:rootCA.key > director_creds/rootCA.key

cat > director_creds/env <<YAML
export BOSH_ENVIRONMENT=https://$BOSH_IP:25555
export BOSH_CA_CERT=\$(pwd)/director_creds/rootCA.key
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(safe get ${VAULT_PREFIX}/users:admin_password)
YAML
