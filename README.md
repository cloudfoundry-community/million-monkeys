# Million Monkeys

Compile all community BOSH releases against the latest stemcell.

Primarily this project describes a large Concourse CI pipeline.

Whenever a new stemcell is published, all community BOSH releases are deployed; then their compiled packages are exported.

![sample](docs/million-monkeys-sample-pipeline.png)
