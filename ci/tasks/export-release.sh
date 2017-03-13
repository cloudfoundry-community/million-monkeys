#!/bin/bash

set -eu

: ${BOSH_DEPLOYMENT:?required}
: ${RELEASE_ORG_NAME:?required}
: ${BUCKET_URL:?required}

export BOSH_ENVIRONMENT=`bosh-cli int director-state/director-creds.yml --path /internal_ip`
export BOSH_CA_CERT="$(bosh-cli int director-state/director-creds.yml --path /director_ssl/ca)"
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh-cli int director-state/director-creds.yml --path /admin_password`

set -x

STEMCELL_OS=${STEMCELL_OS:-ubuntu-trusty}
STEMCELL_VERSION=$(cat stemcell/version)

#
# release metadata/upload
#

cd release
tar -xzf *.tgz $( tar -tzf *.tgz | grep 'release.MF' )
RELEASE_NAME=$( grep -E '^name: ' release.MF | awk '{print $2}' | tr -d "\"'" )
RELEASE_VERSION=$( grep -E '^version: ' release.MF | awk '{print $2}' | tr -d "\"'" )

bosh-cli -n upload-release *.tgz
cd ../

#
# compilation deployment
#

cat > manifest.yml <<EOF
---
name: $BOSH_DEPLOYMENT
releases:
- name: "$RELEASE_NAME"
  version: "$RELEASE_VERSION"
stemcells:
- alias: default
  os: "$STEMCELL_OS"
  version: "$STEMCELL_VERSION"
update:
  canaries: 1
  max_in_flight: 1
  canary_watch_time: 1000 - 90000
  update_watch_time: 1000 - 90000
instance_groups: []
EOF

bosh-cli -n -d $BOSH_DEPLOYMENT deploy manifest.yml
bosh-cli -d $BOSH_DEPLOYMENT export-release $RELEASE_NAME/$RELEASE_VERSION $STEMCELL_OS/$STEMCELL_VERSION

# stannis-12.0-ubuntu-trusty-3363.12-20170312-150301-020284203-20170312150310.tgz
mkdir -p $(dirname compiled-release/$RELEASE_ORG_NAME)
mv *.tgz compiled-release/$RELEASE_ORG_NAME-$RELEASE_VERSION-$STEMCELL_OS-$STEMCELL_VERSION.tgz
sha1sum compiled-release/$RELEASE_ORG_NAME*.tgz

RELEASE_SHA1=$(sha1sum compiled-release/$RELEASE_ORG_NAME*.tgz | awk '{print $1}')
cd compiled-release/
RELEASE_FILENAME=$(ls $RELEASE_ORG_NAME*.tgz)
cd -

cat > compiled-release/$RELEASE_ORG_NAME-latest.spruce.yml <<YAML
---
releases:
- name: $RELEASE_NAME
  version: $RELEASE_VERSION
  sha1: $RELEASE_SHA1
  url: $BUCKET_URL/$RELEASE_FILENAME
YAML
cp compiled-release/$RELEASE_ORG_NAME-{latest,$RELEASE_VERSION}.spruce.yml

cat > compiled-release/$RELEASE_ORG_NAME-latest.patch.yml <<YAML
- type: replace
  path: /releases/name=$RELEASE_NAME?
  value:
    name: $RELEASE_NAME
    version: $RELEASE_VERSION
    sha1: $RELEASE_SHA1
    url: $BUCKET_URL/$RELEASE_FILENAME
YAML
cp compiled-release/$RELEASE_ORG_NAME-{latest,$RELEASE_VERSION}.patch.yml

#
# cleanup
#

bosh-cli -n -d $BOSH_DEPLOYMENT delete-deployment

# curl -k https://genesis.starkandwayne.com/v1/stemcell/latest | jq .
# curl -k https://genesis.starkandwayne.com/v1/stemcell/latest | jq -r ". |= {\"stemcells\": .}" | spruce merge -
# curl -sk https://genesis.starkandwayne.com/v1/stemcell/bosh-aws-xen-hvm-ubuntu-trusty-go_agent
# stemcells:
# - name: bosh-aws-xen-hvm-ubuntu-trusty-go_agent
#   sha1: 3f4251c27a1173812199ae6301dc968660d8ae8b
#   url: https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent?v=3363.12
#   version: "3363.12"

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

stemcell_short=vsphere-esxi
stemcell_name=bosh-${stemcell_short}-ubuntu-trusty-go_agent
stemcell_json=$(curl -sk https://genesis.starkandwayne.com/v1/stemcell/$stemcell_name | jq -r ".[] | select(.version == \"$STEMCELL_VERSION\")")
if [[ "${stemcell_json:-null}" != "null" ]]; then
  cp resource_pools.spruce.yml compiled-stemcell/stemcell-$stemcell_short.spruce.yml
  spruce merge <(echo $stemcell_json) | indent_value >> compiled-stemcell/stemcell-$stemcell_short.spruce.yml

  cp resource_pools.patch.yml compiled-stemcell/stemcell-$stemcell_short.patch.yml
  spruce merge <(echo $stemcell_json) | indent_value >> compiled-stemcell/stemcell-$stemcell_short.patch.yml
fi
