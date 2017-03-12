# Million Monkeys

Compile all community BOSH releases against the latest stemcell.

Primarily this project describes a large Concourse CI pipeline.

Whenever a new stemcell is published, all community BOSH releases are deployed; then their compiled packages are exported.

[![sample](docs/million-monkeys-sample-pipeline.png)](https://ci.starkandwayne.com/teams/main/pipelines/million-monkeys)

* [CI pipeline in action](https://ci.starkandwayne.com/teams/main/pipelines/million-monkeys)

## Usage

A sample use case for `bosh-cli create-env` or `bosh-cli int`:

```
bosh-cli int bosh.yml \
  -o <(curl -s https://s3.amazonaws.com/million-monkeys-releases-latest/cloudfoundry/bosh-latest.patch.yml)
```

Another is with `spruce merge`:

```
spruce merge bosh.yml
  <(curl -s https://s3.amazonaws.com/million-monkeys-releases-latest/cloudfoundry/bosh-latest.spruce.yml)
```

Note the slight differences in the suffix above: `.spruce.yml` vs `.patch.yml`.

## Add new release

Create a file in `releases/`.

If the release is on https://bosh.io/releases then simply run:

```yaml
./ci/add-bosh-io-release.sh cloudfoundry-community/your-boshrelease
```

If the release is available as a `tgz` attachment to a GitHub release, then create the following `releases/your-boshrelease.yml` file:

```yaml
---
release:
  release_label: credhub-release
  release_org_name: pivotal-cf/credhub-release

resources:
- name: (( grab release.release_label ))
  type: github-release
  source:
    user: pivotal-cf
    repository: (( grab release.release_label ))
    access_token: {{GITHUB_TOKEN}}
    pre_release: true
```

In the example above, at the time https://pivotal-cf/credhub-release/releases were tagged "pre-release", so `pre_release: true` is set.

Submit a PR, and the additional release will be generated into the pipeline soon.

## Updating pipeline

After merging PRs, update the pipeline with:

```
./ci/repipe.yml
```
