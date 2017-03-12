#!/bin/bash

set -eu

: ${BOSH_DEPLOYMENT:?required}
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
mv *.tgz compiled-release/$RELEASE_NAME-$RELEASE_VERSION-$STEMCELL_OS-$STEMCELL_VERSION.tgz
sha1sum compiled-release/*.tgz

RELEASE_SHA1=$(sha1sum compiled-release/*.tgz | awk '{print $1}')
RELEASE_FILENAME=$(basename compiled-release/*.tgz)

cat > compiled-release/$RELEASE_NAME-latest.spruce.yml <<YAML
---
releases:
- name: $RELEASE_NAME
  version: $RELEASE_VERSION
  sha1: $RELEASE_SHA1
  url: $BUCKET_URL/$RELEASE_FILENAME
YAML
cp compiled-release/$RELEASE_NAME-{latest,$RELEASE_VERSION}.spruce.yml

cat > compiled-release/$RELEASE_NAME-latest.patch.yml <<YAML
- type: replace
  path: /releases/name=$RELEASE_NAME?
  value:
    name: $RELEASE_NAME
    version: $RELEASE_VERSION
    sha1: $RELEASE_SHA1
    url: $BUCKET_URL/$RELEASE_FILENAME
YAML
cp compiled-release/$RELEASE_NAME-{latest,$RELEASE_VERSION}.patch.yml

#
# cleanup
#

bosh-cli -n -d $BOSH_DEPLOYMENT delete-deployment
