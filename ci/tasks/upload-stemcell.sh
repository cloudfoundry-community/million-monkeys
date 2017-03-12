#!/bin/bash

set -eu

export BOSH_ENVIRONMENT=`bosh-cli int director-state/director-creds.yml --path /internal_ip`
export BOSH_CA_CERT="$(bosh-cli int director-state/director-creds.yml --path /director_ssl/ca)"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh-cli int director-state/director-creds.yml --path /admin_password`

set -x

bosh-cli -n upload-stemcell stemcell/*.tgz
