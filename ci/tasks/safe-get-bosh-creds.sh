#!/bin/bash

safe -k target ci ${VAULT_TARGET:?required}
echo ${GITHUB_TOKEN:?required} | safe auth github

safe get ${VAULT_PREFIX:?required}
