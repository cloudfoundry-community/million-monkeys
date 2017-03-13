#!/bin/bash

set -eu

export BOSH_ENVIRONMENT=`bosh-cli int director-state/director-creds.yml --path /internal_ip`
export BOSH_CA_CERT="$(bosh-cli int director-state/director-creds.yml --path /director_ssl/ca)"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh-cli int director-state/director-creds.yml --path /admin_password`

bosh-cli -n upload-stemcell stemcell/*.tgz

tar -xzf stemcell/*.tgz $( tar -tzf stemcell/*.tgz | grep 'stemcell.MF' )
STEMCELL_OS=$( grep -E '^operating_system: ' stemcell.MF | awk '{print $2}' | tr -d "\"'" )
STEMCELL_VERSION=$( grep -E '^version: ' stemcell.MF | awk '{print $2}' | tr -d "\"'" )

indent_value() {
  c="s/^/    /"
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

cat > resource_pools.spruce.yml <<YAML
---
resource_pools:
- name: vms
  stemcell:
YAML
cat > resource_pools.patch.yml <<YAML
---
- type: replace
  path: /resource_pools/name=vms/stemcell?
  value:
YAML

stemcells_short=(vsphere-esxi warden-boshlite aws-xen-hvm azure-hyperv google-kvm softlayer-xen openstack-kvm)
for stemcell_short in "${stemcells_short[@]}"; do
  stemcell_name=bosh-${stemcell_short}-ubuntu-trusty-go_agent
  stemcell_json=$(curl -sk https://genesis.starkandwayne.com/v1/stemcell/$stemcell_name | jq -r ".[] | select(.version == \"$STEMCELL_VERSION\")")
  if [[ "${stemcell_json:-null}" != "null" ]]; then
    cp resource_pools.spruce.yml compiled-stemcell/stemcell-$stemcell_short.spruce.yml
    spruce merge <(echo $stemcell_json) | indent_value >> compiled-stemcell/stemcell-$stemcell_short.spruce.yml

    cp resource_pools.patch.yml compiled-stemcell/stemcell-$stemcell_short.patch.yml
    spruce merge <(echo $stemcell_json) | indent_value >> compiled-stemcell/stemcell-$stemcell_short.patch.yml
    echo "Created stemcell yml: $stemcell_name"
  else
    echo "!! Unknown stemcell name on genesis: $stemcell_name"
  fi
done
