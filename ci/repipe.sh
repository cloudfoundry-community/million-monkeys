#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

set -e
spruce --concourse merge pipeline-base.yml > pipeline.yml
for release in $(ls releases/*.yml); do
  echo merging $release
  spruce --concourse merge release.yml $release > release-next.yml
  spruce --concourse merge pipeline.yml release-next.yml > pipeline-with-releases-plus1.yml
  mv pipeline-with-releases-plus1.yml pipeline.yml
  rm release-next.yml
done

for stemcell_short in $(cat stemcells); do
  echo merging $stemcell_short
  cat > stemcell_short.yml <<YAML
---
stemcell_short: $stemcell_short
YAML
  spruce --concourse merge --prune stemcell_short stemcell.yml stemcell_short.yml > stemcell-next.yml
  spruce --concourse merge pipeline.yml stemcell-next.yml > pipeline-with-stemcell.yml
  mv pipeline-with-stemcell.yml pipeline.yml
  rm stemcell_short.yml stemcell-next.yml
done

cd $DIR/..
fly -t vsphere sp -p $(basename $(pwd)) -c ci/pipeline.yml -l <(spruce merge ci/credentials.yml)
