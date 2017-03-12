#!/bin/bash

safe -k target ci ${VAULT_TARGET:?required}
echo ${GITHUB_TOKEN:?required} | safe auth github

: ${VAULT_PREFIX:?required}

export BOSH_IP=$(safe get ${VAULT_PREFIX}/env:ip)
safe get ${VAULT_PREFIX}/certs:rootCA.key > director_creds/rootCA.key

cat > director-creds.spruce.yml <<YAML
---
internal_ip: (( vault $VAULT_PREFIX "/env:ip" ))
admin_password: (( vault $VAULT_PREFIX "/users:admin_password" ))
director_ssl:
  ca: (( vault $VAULT_PREFIX "/certs:rootCA.key" ))
YAML

spruce merge director-creds.spruce.yml > director-state/director-creds.yml
