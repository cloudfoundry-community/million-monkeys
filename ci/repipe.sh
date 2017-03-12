#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

set -x -e
spruce --concourse merge pipeline.yml > pipeline-with-releases.yml
for release in $(ls releases/*.yml); do
  spruce --concourse merge release.yml $release > release-next.yml
  spruce --concourse merge pipeline-with-releases.yml release-next.yml > pipeline-with-releases-plus1.yml
  mv pipeline-with-releases{-plus1,}.yml
  rm release-next.yml
done

cd $DIR/..
fly -t vsphere sp -p $(basename $(pwd)) -c ci/pipeline-with-releases.yml -l <(spruce merge ci/credentials.yml)
