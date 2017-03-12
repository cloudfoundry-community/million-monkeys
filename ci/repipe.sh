#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

set -x -e
spruce --concourse merge pipeline-base.yml > pipeline.yml
for release in $(ls releases/*.yml); do
  spruce --concourse merge release.yml $release > release-next.yml
  spruce --concourse merge pipeline.yml release-next.yml > pipeline-with-releases-plus1.yml
  mv pipeline-with-releases-plus1.yml pipeline.yml
  rm release-next.yml
done

cd $DIR/..
fly -t vsphere sp -p $(basename $(pwd)) -c ci/pipeline.yml -l <(spruce merge ci/credentials.yml)
