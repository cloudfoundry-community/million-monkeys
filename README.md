# Million Monkeys

Compile all community BOSH releases against the latest stemcell.

Primarily this project describes a large Concourse CI pipeline.

Whenever a new stemcell is published, all community BOSH releases are deployed; then their compiled packages are exported.

[![sample](docs/million-monkeys-sample-pipeline.png)](https://ci.starkandwayne.com/teams/main/pipelines/million-monkeys)

* [CI pipeline in action](https://ci.starkandwayne.com/teams/main/pipelines/million-monkeys)

## Add new release

Create a file in `releases/`.

If the release is on https://bosh.io/releases then your file will look like:

```yaml
---
release:
  release_label: stannis-boshrelease
  release_org_name: cloudfoundry-community/stannis-boshrelease
```

The `release.release_label` is what appears as the CI job name.

If the release is available as a `tgz` attachment to a GitHub release:

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

```
./ci/repipe.yml
```
