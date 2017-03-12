FROM bosh/compiled-release

ADD https://github.com/geofffranks/spruce/releases/download/v1.8.13/spruce-linux-amd64 /usr/bin/spruce
ADD https://github.com/starkandwayne/safe/releases/download/v0.1.3/safe-linux-amd64 /usr/bin/safe

RUN chmod 755 /usr/bin/spruce /usr/bin/safe

ENV VAULT_VERSION 0.6.5
RUN wget -qO /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
      unzip -d /usr/bin /tmp/vault.zip && rm /tmp/vault.zip && chmod 755 /usr/bin/vault
