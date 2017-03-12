#!/bin/sh

set -eux

export BOSH_ENVIRONMENT=${BOSH_ENVIRONMENT:?required}
export BOSH_CA_CERT=${BOSH_CA_CERT:?required}
export BOSH_CLIENT=${BOSH_CLIENT:?required}
export BOSH_CLIENT_SECRET=${BOSH_CLIENT_SECRET:?required}
export BOSH_DEPLOYMENT=${BOSH_DEPLOYMENT:?required}

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

mv *.tgz compiled-release/$( echo *.tgz | sed "s/\.tgz$/-$( date -u +%Y%m%d%H%M%S ).tgz/" )
sha1sum compiled-release/*.tgz

#
# cleanup
#

bosh-cli -n -d $BOSH_DEPLOYMENT delete-deployment
