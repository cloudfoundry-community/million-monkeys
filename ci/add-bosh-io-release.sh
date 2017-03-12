#!/bin/bash

release_org_name=$1
if [[ "${release_org_name:-X}" == "X" ]]; then
  echo "USAGE: ./ci/add-bosh-io-release.sh cloudfoundry/cf-release"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

release_label=$(basename $release_org_name)

set +x
cat > releases/$release_label.yml <<YAML
---
release:
  release_label: ${release_label}
  release_org_name: ${release_org_name}
YAML

cat releases/$release_label.yml

echo Next run: ./ci/repipe.sh
