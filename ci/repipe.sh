#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

set -e

echo fetching credentials
spruce --concourse merge pipeline-base.yml creds.yml > pipeline.yml
for release in $(ls releases/*.yml); do
  echo merging $release
  spruce merge pipeline.yml release.yml $release > pipeline-next.yml
  mv pipeline-next.yml pipeline.yml
done

for stemcell_short in $(cat stemcells); do
  echo merging $stemcell_short
  cat > stemcell_short.yml <<YAML
---
stemcell_short: $stemcell_short
YAML
  spruce merge pipeline.yml stemcell.yml stemcell_short.yml > pipeline-next.yml
  mv pipeline-next.yml pipeline.yml
  rm stemcell_short.yml
done

cd $DIR/..
fly -t vsphere sp -p $(basename $(pwd)) -c ci/pipeline.yml
rm ci/pipeline.yml
